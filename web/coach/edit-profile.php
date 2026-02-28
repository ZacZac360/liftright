<?php
// liftright/web/coach/edit-profile.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';
require_once __DIR__ . '/../includes/profile_change_helpers.php';

require_role(['trainer']);
$page_title = "Edit Profile";

$user_id = (int)($_SESSION['user_id'] ?? 0);

if (!function_exists('h')) {
  function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
}

function ext_from_mime(string $mime): ?string {
  return match (strtolower($mime)) {
    'image/jpeg' => 'jpg',
    'image/png'  => 'png',
    default      => null
  };
}

/* ----- Fetch current approved profile from users ----- */
$stmt = $mysqli->prepare("
  SELECT user_id, full_name, email,
         birthdate, gender, bio, profile_photo,
         qualification, years_experience, specializations
  FROM users
  WHERE user_id = ?
  LIMIT 1
");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$user = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$user) {
  header("Location: {$BASE_URL}/logout.php");
  exit;
}

/* ----- Block if pending request exists ----- */
$pending = get_pending_profile_request($mysqli, $user_id);

$errors = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  if ($pending) {
    $errors[] = "You already have a pending profile update request. Cancel it first.";
  } else {

    $full_name = trim((string)($_POST['full_name'] ?? ''));
    $email     = trim((string)($_POST['email'] ?? ''));
    $birthdate = trim((string)($_POST['birthdate'] ?? ''));
    $gender    = trim((string)($_POST['gender'] ?? ''));
    $bio       = trim((string)($_POST['bio'] ?? ''));
    $qualification = trim((string)($_POST['qualification'] ?? ''));
    $years_exp_raw = trim((string)($_POST['years_experience'] ?? ''));
    $specializations_raw = trim((string)($_POST['specializations'] ?? ''));

    $years_experience = ($years_exp_raw === '') ? null : (int)$years_exp_raw;

    // validate
    if ($full_name === '' || mb_strlen($full_name) > 120) $errors[] = "Full name is required (max 120 chars).";
    if ($email === '' || mb_strlen($email) > 190 || !filter_var($email, FILTER_VALIDATE_EMAIL)) $errors[] = "Enter a valid email.";
    if ($birthdate !== '') {
      $ts = strtotime($birthdate);
      if (!$ts) $errors[] = "Birthdate is invalid.";
      else {
        $y = (int)date('Y', $ts);
        $currentY = (int)date('Y');
        if ($y < 1900 || $y > $currentY) $errors[] = "Birthdate is unrealistic.";
      }
    }
    $allowedGender = ['male','female','other','prefer_not_to_say',''];
    if (!in_array($gender, $allowedGender, true)) $errors[] = "Select a valid gender option.";
    if (mb_strlen($bio) > 800) $errors[] = "Bio is too long (max 800 chars).";
    if (mb_strlen($qualification) > 190) $errors[] = "Qualification too long (max 190 chars).";
    if ($years_experience !== null && $years_experience > 80) $errors[] = "Years of experience is unrealistic.";

    // prevent email collision (except yourself)
    if (!$errors) {
      $stmt = $mysqli->prepare("SELECT 1 FROM users WHERE email = ? AND user_id <> ? LIMIT 1");
      $stmt->bind_param("si", $email, $user_id);
      $stmt->execute();
      $exists = $stmt->get_result()->num_rows > 0;
      $stmt->close();
      if ($exists) $errors[] = "That email is already in use.";
    }

    // specializations: comma-separated -> JSON array
    $specArr = null;
    if (!$errors) {
      $parts = array_filter(array_map('trim', explode(',', $specializations_raw)), fn($x) => $x !== '');
      if (count($parts) > 30) $errors[] = "Too many specializations (max 30).";
      else $specArr = $parts ? json_encode(array_values($parts)) : null;
    }

    // handle profile photo upload (optional)
    $pendingPhotoPath = null;
    if (!$errors && isset($_FILES['profile_photo']) && (int)$_FILES['profile_photo']['error'] !== UPLOAD_ERR_NO_FILE) {
      if ((int)$_FILES['profile_photo']['error'] !== UPLOAD_ERR_OK) {
        $errors[] = "Profile photo upload failed. Try again.";
      } else {
        $tmpPath = (string)$_FILES['profile_photo']['tmp_name'];
        $mime = function_exists('mime_content_type') ? (string)mime_content_type($tmpPath) : '';
        $ext = $mime ? ext_from_mime($mime) : null;

        if (!$ext) {
          $orig = strtolower((string)($_FILES['profile_photo']['name'] ?? ''));
          if (str_ends_with($orig, '.jpg') || str_ends_with($orig, '.jpeg')) $ext = 'jpg';
          elseif (str_ends_with($orig, '.png')) $ext = 'png';
        }
        if (!$ext) {
          $errors[] = "Profile photo must be JPG or PNG.";
        } else {
          $size = (int)$_FILES['profile_photo']['size'];
          if ($size <= 0 || $size > 3 * 1024 * 1024) {
            $errors[] = "Profile photo must be under 3MB.";
          } else {
            $relDir = "uploads/pending_profiles";
            $absDir = __DIR__ . "/../" . $relDir;
            if (!is_dir($absDir)) @mkdir($absDir, 0775, true);

            $safeName = "p_" . $user_id . "_" . bin2hex(random_bytes(6)) . "." . $ext;
            $absDest = $absDir . "/" . $safeName;

            if (!move_uploaded_file($tmpPath, $absDest)) {
              $errors[] = "Failed to save profile photo. Try again.";
            } else {
              $pendingPhotoPath = $relDir . "/" . $safeName; // store relative path
            }
          }
        }
      }
    }

    // create request
    if (!$errors) {
      $stmt = $mysqli->prepare("
        INSERT INTO profile_change_requests
          (user_id,
           requested_full_name, requested_email, requested_age,
           requested_birthdate, requested_gender, requested_bio, requested_profile_photo,
           requested_qualification, requested_years_experience, requested_specializations,
           status)
        VALUES
          (?, ?, ?, NULL, ?, ?, ?, ?, ?, ?, ?, 'pending')
      ");

      $birthdateParam = ($birthdate === '') ? null : $birthdate;
      $genderParam    = ($gender === '') ? null : $gender;
      $bioParam       = ($bio === '') ? null : $bio;
      $qualParam      = ($qualification === '') ? null : $qualification;
      $yearsParam     = $years_experience; // nullable
      $specParam      = $specArr;          // nullable JSON string
      $photoParam     = $pendingPhotoPath; // nullable

      $stmt->bind_param(
        "isssssssis",
        $user_id,
        $full_name,
        $email,
        $birthdateParam,
        $genderParam,
        $bioParam,
        $photoParam,
        $qualParam,
        $yearsParam,
        $specParam
      );
      // IMPORTANT: bind_param signature above has a space in it in this editor in some cases.
      // If your PHP errors, use the corrected bind block below (copy-paste it exactly).

      $stmt->execute();
      $stmt->close();

      // Notify admins
      if (function_exists('notify_all_admins')) {
        notify_all_admins(
          $mysqli,
          "Profile change request submitted by {$full_name} ({$email}).",
          null,
          $user_id
        );
      }

      header("Location: {$BASE_URL}/coach/profile.php?updated=1");
      exit;
    }
  }
}

/* ---- Correct bind_param block (copy this over the bind_param section if PHP complains) ----
$stmt->bind_param(
  "isssssssiis",
  $user_id,
  $full_name,
  $email,
  $birthdateParam,
  $genderParam,
  $bioParam,
  $photoParam,
  $qualParam,
  $yearsParam,
  $specParam
);
------------------------------------------------------------------------------------------ */

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="lr-page-wrapper">
  <div class="container lr-main-container py-4">

    <div class="row mb-4 align-items-center">
      <div class="col-md-8">
        <div class="lr-section-title mb-1">Account</div>
        <h1 class="lr-section-heading mb-1">Edit Profile</h1>
        <p class="lr-stat-subtext mb-0">Changes require admin approval before they take effect.</p>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0">
        <a class="btn btn-outline-light btn-sm" href="<?= $BASE_URL ?>/coach/profile.php">Back to Profile</a>
      </div>
    </div>

    <?php if ($pending): ?>
      <div class="alert alert-warning">
        You already have a pending request submitted on
        <strong><?= h(date("M d, Y • g:i A", strtotime((string)$pending['created_at']))) ?></strong>.
        Cancel it from your profile page before submitting a new one.
      </div>
    <?php endif; ?>

    <?php if ($errors): ?>
      <div class="alert alert-danger">
        <div class="fw-semibold mb-1">Fix these:</div>
        <ul class="mb-0">
          <?php foreach ($errors as $e): ?><li><?= h($e) ?></li><?php endforeach; ?>
        </ul>
      </div>
    <?php endif; ?>

    <div class="lr-card" style="max-width: 860px;">
      <div class="lr-card-header">
        <div class="lr-section-title mb-1">Request</div>
        <div class="lr-section-heading mb-0">Profile update (admin approval)</div>
      </div>

      <div class="lr-card-body">
        <form method="post" enctype="multipart/form-data">
          <div class="row g-3">

            <div class="col-12">
              <label class="form-label lr-stat-label">Full name</label>
              <input class="form-control" name="full_name" required
                     value="<?= h((string)$user['full_name']) ?>" <?= $pending ? 'disabled' : '' ?>>
            </div>

            <div class="col-12">
              <label class="form-label lr-stat-label">Email</label>
              <input class="form-control" name="email" type="email" required
                     value="<?= h((string)$user['email']) ?>" <?= $pending ? 'disabled' : '' ?>>
            </div>

            <div class="col-md-6">
              <label class="form-label lr-stat-label">Birthdate</label>
              <input class="form-control" name="birthdate" type="date"
                     value="<?= h((string)($user['birthdate'] ?? '')) ?>" <?= $pending ? 'disabled' : '' ?>>
            </div>

            <div class="col-md-6">
              <label class="form-label lr-stat-label">Gender</label>
              <select class="form-control" name="gender" <?= $pending ? 'disabled' : '' ?>>
                <?php $g = (string)($user['gender'] ?? ''); ?>
                <option value="" <?= $g===''?'selected':'' ?>>Prefer not to say</option>
                <option value="male" <?= $g==='male'?'selected':'' ?>>Male</option>
                <option value="female" <?= $g==='female'?'selected':'' ?>>Female</option>
                <option value="other" <?= $g==='other'?'selected':'' ?>>Other</option>
                <option value="prefer_not_to_say" <?= $g==='prefer_not_to_say'?'selected':'' ?>>Prefer not to say</option>
              </select>
            </div>

            <div class="col-12">
              <label class="form-label lr-stat-label">Bio</label>
              <textarea class="form-control" name="bio" rows="3" <?= $pending ? 'disabled' : '' ?>
                        placeholder="Short intro (max 800 chars)"><?= h((string)($user['bio'] ?? '')) ?></textarea>
            </div>

            <div class="col-md-6">
              <label class="form-label lr-stat-label">Qualification</label>
              <input class="form-control" name="qualification"
                     value="<?= h((string)($user['qualification'] ?? '')) ?>" <?= $pending ? 'disabled' : '' ?>>
            </div>

            <div class="col-md-6">
              <label class="form-label lr-stat-label">Years of experience</label>
              <input class="form-control" name="years_experience" type="number" min="0" max="80"
                     value="<?= $user['years_experience'] === null ? '' : (int)$user['years_experience'] ?>"
                     <?= $pending ? 'disabled' : '' ?>>
            </div>

            <div class="col-12">
              <label class="form-label lr-stat-label">Specializations (comma-separated)</label>
              <?php
                $spec = $user['specializations'];
                $specText = '';
                if ($spec) {
                  if (is_string($spec)) {
                    // might already be JSON string
                    $decoded = json_decode($spec, true);
                    if (is_array($decoded)) $specText = implode(', ', $decoded);
                    else $specText = $spec;
                  } else {
                    $specText = json_encode($spec);
                  }
                }
              ?>
              <input class="form-control" name="specializations"
                     value="<?= h($specText) ?>" <?= $pending ? 'disabled' : '' ?>>
            </div>

            <div class="col-12">
              <label class="form-label lr-stat-label">Profile photo (upload)</label>
              <input id="photoFile" type="file" name="profile_photo" class="form-control"
                     accept=".jpg,.jpeg,.png" <?= $pending ? 'disabled' : '' ?>>

              <div class="lr-stat-subtext mt-2">
                Or take a photo using your camera (saved as an upload).
              </div>

              <div class="d-flex gap-2 align-items-center mt-2 flex-wrap">
                <button type="button" class="btn btn-outline-light btn-sm" id="btnOpenCam" <?= $pending ? 'disabled' : '' ?>>Open camera</button>
                <button type="button" class="btn btn-outline-light btn-sm" id="btnCapture" disabled>Capture</button>
                <button type="button" class="btn btn-outline-light btn-sm" id="btnCloseCam" disabled>Close</button>
                <span class="small" id="camStatus" style="opacity:.85;">Camera closed</span>
              </div>

              <div class="mt-3" style="display:grid;grid-template-columns:1fr 1fr;gap:12px;align-items:start;">
                <video id="camVideo" playsinline autoplay style="width:100%;border-radius:12px;display:none;background:rgba(0,0,0,.25);"></video>
                <img id="photoPreview" alt="Preview" style="width:100%;border-radius:12px;display:none;object-fit:cover;background:rgba(255,255,255,.06);">
              </div>

              <canvas id="camCanvas" style="display:none;"></canvas>
            </div>

          </div>

          <div class="d-flex gap-2 mt-4">
            <button class="btn btn-primary" type="submit" <?= $pending ? 'disabled' : '' ?>>
              Submit for Approval
            </button>
            <a class="btn btn-outline-light" href="<?= $BASE_URL ?>/coach/profile.php">Cancel</a>
          </div>

          <div class="lr-stat-subtext mt-3 mb-0">
            After submission, admins can approve/reject your request.
          </div>
        </form>
      </div>
    </div>

  </div>
</div>

<script>
(() => {
  const openBtn   = document.getElementById('btnOpenCam');
  const capBtn    = document.getElementById('btnCapture');
  const closeBtn  = document.getElementById('btnCloseCam');
  const statusEl  = document.getElementById('camStatus');
  const video     = document.getElementById('camVideo');
  const canvas    = document.getElementById('camCanvas');
  const preview   = document.getElementById('photoPreview');
  const fileInput = document.getElementById('photoFile');

  let stream = null;

  async function openCam(){
    try {
      stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: false });
      video.srcObject = stream;
      video.style.display = 'block';
      capBtn.disabled = false;
      closeBtn.disabled = false;
      statusEl.textContent = 'Camera open';
    } catch (e) {
      statusEl.textContent = 'Camera failed to open';
      alert('Could not access camera. Check permissions.');
    }
  }

  function closeCam(){
    if (stream) stream.getTracks().forEach(t => t.stop());
    stream = null;
    video.srcObject = null;
    video.style.display = 'none';
    capBtn.disabled = true;
    closeBtn.disabled = true;
    statusEl.textContent = 'Camera closed';
  }

  async function capture(){
    if (!video.videoWidth) return;
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    const ctx = canvas.getContext('2d');
    ctx.drawImage(video, 0, 0);

    const blob = await new Promise(res => canvas.toBlob(res, 'image/jpeg', 0.92));
    if (!blob) return;

    // Put captured image into the file input (as if uploaded)
    const file = new File([blob], 'captured_profile.jpg', { type: 'image/jpeg' });
    const dt = new DataTransfer();
    dt.items.add(file);
    fileInput.files = dt.files;

    preview.src = URL.createObjectURL(blob);
    preview.style.display = 'block';
    statusEl.textContent = 'Captured (ready to submit)';
  }

  if (openBtn) openBtn.addEventListener('click', openCam);
  if (closeBtn) closeBtn.addEventListener('click', closeCam);
  if (capBtn) capBtn.addEventListener('click', capture);

  // If user uploads a file, show preview
  if (fileInput) {
    fileInput.addEventListener('change', () => {
      const f = fileInput.files && fileInput.files[0];
      if (!f) return;
      preview.src = URL.createObjectURL(f);
      preview.style.display = 'block';
      statusEl.textContent = 'File selected (ready to submit)';
    });
  }
})();
</script>

<?php require __DIR__ . '/../includes/footer.php'; ?>
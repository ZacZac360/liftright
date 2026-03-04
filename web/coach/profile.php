<?php
// liftright/web/coach/profile.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';
require_once __DIR__ . '/../includes/profile_change_helpers.php';

require_role(['trainer']);

$page_title = "Coach Profile";

$user_id    = (int)($_SESSION['user_id'] ?? 0);
$role       = (string)($_SESSION['role'] ?? 'trainer');

if (!function_exists('h')) {
  function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
}

function calc_age(?string $birthdate): string {
  if (!$birthdate) return '—';
  $ts = strtotime($birthdate);
  if (!$ts) return '—';
  $dob = new DateTime(date('Y-m-d', $ts));
  $now = new DateTime('today');
  return (string)$dob->diff($now)->y;
}

/* ----- Fetch current approved profile from users ----- */
$stmt = $mysqli->prepare("
SELECT user_id, full_name, email,
       birthdate, gender, bio, profile_photo,
       qualification, years_experience, specializations,
       accepting_trainees
  FROM users
  WHERE user_id = ?
  LIMIT 1
");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$u = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$u) {
  header("Location: {$BASE_URL}/logout.php");
  exit;
}

/* ----- Pending profile request (admin approval) ----- */
$pending = get_pending_profile_request($mysqli, $user_id);

/* ----- Rating summary (new system) ----- */
$total_reviews = 0;
$avg_rating    = 0.0;

$stmt = $mysqli->prepare("
  SELECT avg_rating, review_count
  FROM trainer_rating_summary
  WHERE trainer_id = ?
  LIMIT 1
");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$rs = $stmt->get_result()->fetch_assoc();
$stmt->close();

if ($rs) {
  $avg_rating    = (float)($rs['avg_rating'] ?? 0);
  $total_reviews = (int)($rs['review_count'] ?? 0);
}

/* ----- Toggle accepting trainees ----- */
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['toggle_accepting'])) {

  $new_value = (int)($_POST['accepting'] ?? 0);
  $new_value = $new_value ? 1 : 0;

  $stmt = $mysqli->prepare("
    UPDATE users
    SET accepting_trainees = ?
    WHERE user_id = ?
    LIMIT 1
  ");
  $stmt->bind_param("ii", $new_value, $user_id);
  $stmt->execute();
  $stmt->close();

  header("Location: {$BASE_URL}/coach/profile.php");
  exit;
}

/* ----- Cancel pending request (POST) ----- */
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['cancel_request_id'])) {
  $rid = (int)$_POST['cancel_request_id'];
  if (cancel_profile_request($mysqli, $rid, $user_id)) {
    header("Location: {$BASE_URL}/coach/profile.php?cancelled=1");
    exit;
  }
}

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="lr-page-wrapper">
  <div class="container lr-main-container py-4">

    <div class="row mb-4 align-items-center">
      <div class="col-md-8">
        <div class="lr-section-title mb-1">Account</div>
        <h1 class="lr-section-heading mb-1">Coach Profile</h1>
        <p class="lr-stat-subtext mb-0">Your approved profile + pending updates (admin approval required).</p>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0">
        <a class="btn btn-outline-light btn-sm" href="<?= $BASE_URL ?>/coach/dashboard.php">Back to Dashboard</a>
      </div>
    </div>

    <?php if (isset($_GET['updated'])): ?>
      <div class="alert alert-success">Profile update request submitted. Waiting for admin approval.</div>
    <?php endif; ?>
    <?php if (isset($_GET['cancelled'])): ?>
      <div class="alert alert-info">Pending request cancelled.</div>
    <?php endif; ?>

    <?php if ($pending): ?>
      <div class="alert alert-warning">
        <div class="fw-semibold">Awaiting admin approval</div>
        <div class="small" style="opacity:.9;">
          Submitted: <?= h(date("M d, Y • g:i A", strtotime((string)$pending['created_at']))) ?>
        </div>

        <div class="mt-2 small" style="opacity:.95;">
          <div><b>Requested changes:</b></div>
          <?php if (!empty($pending['requested_full_name'])): ?>
            <div>• Name: <?= h((string)$pending['requested_full_name']) ?></div>
          <?php endif; ?>
          <?php if (!empty($pending['requested_email'])): ?>
            <div>• Email: <?= h((string)$pending['requested_email']) ?></div>
          <?php endif; ?>
          <?php if (!empty($pending['requested_birthdate'])): ?>
            <div>• Birthdate: <?= h((string)$pending['requested_birthdate']) ?></div>
          <?php endif; ?>
          <?php if (!empty($pending['requested_gender'])): ?>
            <div>• Gender: <?= h((string)$pending['requested_gender']) ?></div>
          <?php endif; ?>
          <?php if (!empty($pending['requested_bio'])): ?>
            <div>• Bio: <?= h((string)$pending['requested_bio']) ?></div>
          <?php endif; ?>
          <?php if (!empty($pending['requested_qualification'])): ?>
            <div>• Qualification: <?= h((string)$pending['requested_qualification']) ?></div>
          <?php endif; ?>
          <?php if (!empty($pending['requested_years_experience'])): ?>
            <div>• Years experience: <?= (int)$pending['requested_years_experience'] ?></div>
          <?php endif; ?>
          <?php if (!empty($pending['requested_specializations'])): ?>
            <div>• Specializations: <?= h(json_encode($pending['requested_specializations'])) ?></div>
          <?php endif; ?>
          <?php if (!empty($pending['requested_profile_photo'])): ?>
            <div>• New profile photo uploaded (pending)</div>
          <?php endif; ?>
        </div>

        <form method="post" class="mt-3 mb-0">
          <input type="hidden" name="cancel_request_id" value="<?= (int)$pending['request_id'] ?>">
          <button class="btn btn-sm btn-outline-light" type="submit"
                  onclick="return confirm('Cancel this pending request?');">
            Cancel request
          </button>
        </form>
      </div>
    <?php endif; ?>

    <div class="row g-4">

      <div class="col-lg-5">
        <div class="lr-card">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">Profile</div>
            <div class="lr-section-heading mb-0">Approved details</div>
          </div>
          <div class="lr-card-body">

            <div class="d-flex align-items-center gap-3 mb-3">
              <?php
                $photo = (string)($u['profile_photo'] ?? '');
                $src = $photo ? ($BASE_URL . '/' . ltrim($photo, '/')) : '';
              ?>
              <div style="width:72px;height:72px;border-radius:50%;overflow:hidden;background:rgba(255,255,255,.08);display:flex;align-items:center;justify-content:center;">
                <?php if ($src): ?>
                  <img src="<?= h($src) ?>" alt="Profile photo" style="width:100%;height:100%;object-fit:cover;">
                <?php else: ?>
                  <span style="opacity:.8;">No photo</span>
                <?php endif; ?>
              </div>

              <div>
                <div class="fw-semibold fs-5"><?= h((string)$u['full_name']) ?></div>
                <div class="lr-stat-subtext"><?= h((string)$u['email']) ?></div>
              </div>
            </div>

            <div class="lr-stat-label">Age</div>
            <div class="lr-stat-subtext"><?= h(calc_age($u['birthdate'] ?? null)) ?></div>

            <div class="lr-stat-label mt-3">Gender</div>
            <div class="lr-stat-subtext"><?= h((string)($u['gender'] ?? '—')) ?></div>

            <div class="lr-stat-label mt-3">Bio</div>
            <div class="lr-stat-subtext"><?= h((string)($u['bio'] ?? '—')) ?></div>

            <hr class="border-secondary my-4">

            <div class="lr-stat-label">Qualification</div>
            <div class="lr-stat-subtext"><?= h((string)($u['qualification'] ?? '—')) ?></div>

            <div class="lr-stat-label mt-3">Years of experience</div>
            <div class="lr-stat-subtext"><?= $u['years_experience'] === null ? '—' : (int)$u['years_experience'] ?></div>

            <div class="lr-stat-label mt-3">Specializations</div>
            <div class="lr-stat-subtext">
              <?php
                $specRaw = $u['specializations'] ?? '';
                $out = '—';

                if (is_string($specRaw) && trim($specRaw) !== '') {
                  $trim = trim($specRaw);

                  // If it's JSON, decode to a nice comma list
                  $decoded = json_decode($trim, true);
                  if (is_array($decoded)) {
                    $decoded = array_values(array_filter(array_map('trim', $decoded), fn($x) => $x !== ''));
                    $out = $decoded ? implode(', ', $decoded) : '—';
                  } else {
                    // Otherwise treat as normal string / CSV
                    $out = $trim;
                  }
                }

                echo h($out);
              ?>
            </div>

            <hr class="border-secondary my-4">

            <div class="d-flex justify-content-between align-items-center">
              <div>
                <div class="lr-stat-label">Accepting New Trainees</div>
                <div class="lr-stat-subtext">
                  <?= $u['accepting_trainees'] ? 'Currently accepting requests.' : 'Not accepting new trainees.' ?>
                </div>
              </div>

              <form method="post" class="m-0">
                <input type="hidden" name="toggle_accepting" value="1">
                <input type="hidden" name="accepting" value="<?= $u['accepting_trainees'] ? 0 : 1 ?>">
                <button class="btn <?= $u['accepting_trainees'] ? 'btn-outline-light' : 'btn-primary' ?> btn-sm">
                  <?= $u['accepting_trainees'] ? 'Disable' : 'Enable' ?>
                </button>
              </form>
            </div>
            <?php if (!$pending): ?>
              <a class="btn btn-outline-light mt-3"
                 href="<?= $BASE_URL ?>/coach/edit-profile.php">
                Edit Profile
              </a>
            <?php else: ?>
              <div class="lr-stat-subtext mt-3 mb-0">
                Editing is disabled while a request is pending.
              </div>
            <?php endif; ?>

          </div>
        </div>
      </div>

      <div class="col-lg-7">
        <div class="row g-3">

          <div class="col-md-6">
            <div class="lr-card h-100">
              <div class="lr-card-body">
                <div class="lr-stat-label">Average rating</div>
                <div class="lr-stat-value mt-1"><?= $total_reviews ? h(number_format($avg_rating, 2)) : '—' ?></div>
                <div class="lr-stat-subtext">Based on trainee reviews.</div>
              </div>
            </div>
          </div>

          <div class="col-md-6">
            <div class="lr-card h-100">
              <div class="lr-card-body">
                <div class="lr-stat-label">Total reviews</div>
                <div class="lr-stat-value mt-1"><?= (int)$total_reviews ?></div>
                <div class="lr-stat-subtext">Count of approved reviews.</div>
              </div>
            </div>
          </div>

          <div class="col-12">
            <div class="lr-card">
              <div class="lr-card-header d-flex justify-content-between align-items-center">
                <div>
                  <div class="lr-section-title mb-1">Reviews</div>
                  <div class="lr-section-heading mb-0">Your trainer feedback</div>
                </div>
                <a class="small text-decoration-none" href="<?= $BASE_URL ?>/coach/reviews.php">View reviews</a>
              </div>
              <div class="lr-card-body">
                <div class="lr-stat-subtext mb-0">
                  Reviews affect how trainees filter/search trainers.
                </div>
              </div>
            </div>
          </div>

        </div>
      </div>

    </div>

  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>
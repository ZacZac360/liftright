<?php
session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';
require_once __DIR__ . '/../includes/profile_change_helpers.php';

require_role(['trainer']);
$page_title = "Edit Profile";

$user_id = (int)($_SESSION['user_id'] ?? 0);

$stmt = $mysqli->prepare("
  SELECT user_id, full_name, email, age
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

$pending = get_pending_profile_request($mysqli, $user_id);
$errors = [];
$success = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  if ($pending) {
    $errors[] = "You already have a pending profile update request.";
  } else {
    $full_name = trim((string)($_POST['full_name'] ?? ''));
    $email     = trim((string)($_POST['email'] ?? ''));
    $age_raw   = trim((string)($_POST['age'] ?? ''));
    $age       = ($age_raw === '') ? null : (int)$age_raw;

    if ($full_name === '' || mb_strlen($full_name) > 120) $errors[] = "Please enter a valid full name (max 120 chars).";
    if ($email === '' || mb_strlen($email) > 190 || !filter_var($email, FILTER_VALIDATE_EMAIL)) $errors[] = "Please enter a valid email.";
    if ($age !== null && ($age < 5 || $age > 120)) $errors[] = "Age must be between 5 and 120.";

    // Optional: prevent email collision (except yourself)
    if (!$errors) {
      $stmt = $mysqli->prepare("SELECT 1 FROM users WHERE email = ? AND user_id <> ? LIMIT 1");
      $stmt->bind_param("si", $email, $user_id);
      $stmt->execute();
      $exists = $stmt->get_result()->num_rows > 0;
      $stmt->close();
      if ($exists) $errors[] = "That email is already in use.";
    }

    if (!$errors) {
      $stmt = $mysqli->prepare("
        INSERT INTO profile_change_requests (user_id, requested_full_name, requested_email, requested_age)
        VALUES (?, ?, ?, ?)
      ");
      // NOTE: for nullable int in bind_param, pass as variable and allow null
      $stmt->bind_param("issi", $user_id, $full_name, $email, $age);
      $stmt->execute();
      $stmt->close();

      // Notify admins that this user submitted a profile change request
        notify_all_admins(
        $mysqli,
        "Profile change request submitted by {$full_name} ({$email}).",
        null,
        $user_id
        );

      // Optional notification to admins (later). For now just redirect.
      header("Location: {$BASE_URL}/coach/profile.php?updated=1");
      exit;
    }
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
        You can cancel it from your profile page.
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

    <div class="lr-card" style="max-width: 720px;">
      <div class="lr-card-header">
        <div class="lr-section-title mb-1">Request</div>
        <div class="lr-section-heading mb-0">Profile update</div>
      </div>
      <div class="lr-card-body">
        <form method="post">
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

            <div class="col-md-4">
              <label class="form-label lr-stat-label">Age (optional)</label>
              <input class="form-control" name="age" type="number" min="5" max="120"
                     value="<?= $user['age'] === null ? '' : (int)$user['age'] ?>" <?= $pending ? 'disabled' : '' ?>>
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

<?php require __DIR__ . '/../includes/footer.php'; ?>
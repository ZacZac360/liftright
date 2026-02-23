<?php
// liftright/web/coach/profile.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['trainer']);

require_once __DIR__ . '/../includes/profile_change_helpers.php';
$pending = get_pending_profile_request($mysqli, $user_id);require_once __DIR__ . '/../includes/profile_change_helpers.php';


$page_title = "Coach Profile";

$trainer_id = (int)($_SESSION['user_id'] ?? 0);
$full_name  = (string)($_SESSION['full_name'] ?? 'Coach');
$email      = (string)($_SESSION['email'] ?? '');

$total_reviews = 0;
$avg_rating = 0;
$latest_review = null;

$stmt = $mysqli->prepare("
  SELECT
    COUNT(*) AS c,
    AVG(rating) AS avg_rating,
    MAX(created_at) AS latest
  FROM expert_reviews
  WHERE trainer_id = ?
");
$stmt->bind_param("i", $trainer_id);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

if ($row) {
  $total_reviews = (int)($row['c'] ?? 0);
  $avg_rating = isset($row['avg_rating']) ? (float)$row['avg_rating'] : 0;
  $latest_review = $row['latest'] ?? null;
}

function fmtDT(?string $dt): string {
  if (!$dt) return "—";
  $ts = strtotime($dt);
  return $ts ? date("M d, Y • g:i A", $ts) : $dt;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['cancel_request_id'])) {
  $rid = (int)$_POST['cancel_request_id'];
  if (cancel_profile_request($mysqli, $rid, $user_id)) {
    header("Location: {$BASE_URL}/" . ($_SESSION['role']==='trainer'?'coach':'trainee') . "/profile.php?cancelled=1");
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
        <p class="lr-stat-subtext mb-0">Basic account details + your evaluation activity.</p>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0">
        <a class="btn btn-outline-light btn-sm" href="<?= $BASE_URL ?>/coach/dashboard.php">Back to Dashboard</a>
      </div>
    </div>

    <div class="row g-4">

    <?php if ($pending): ?>
      <div class="alert alert-warning">
        <div class="fw-semibold">Awaiting admin approval</div>
        <div class="lr-stat-subtext mb-2">
          Submitted: <?= h(date("M d, Y • g:i A", strtotime((string)$pending['created_at']))) ?>
        </div>

        <form method="post" action="<?= $BASE_URL ?>/<?= ($_SESSION['role']==='trainer'?'coach':'trainee') ?>/profile.php" class="m-0">
          <input type="hidden" name="cancel_request_id" value="<?= (int)$pending['request_id'] ?>">
          <button class="btn btn-sm btn-outline-light" type="submit"
                  onclick="return confirm('Cancel this pending request?');">
            Cancel request
          </button>
        </form>
      </div>
    <?php endif; ?>

      <div class="col-lg-5">
        <div class="lr-card">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">Profile</div>
            <div class="lr-section-heading mb-0">Your details</div>
          </div>
          <div class="lr-card-body">
            <div class="lr-stat-label">Name</div>
            <div class="fw-semibold fs-5"><?= h($full_name) ?></div>

            <div class="lr-stat-label mt-3">Email</div>
            <div class="lr-stat-subtext"><?= h($email ?: '—') ?></div>

            <div class="lr-stat-label mt-3">Role</div>
            <span class="lr-badge lr-badge-good">trainer</span>

            <hr class="border-secondary my-4">

            <div class="lr-stat-subtext mb-0">
              <?php
                require_once __DIR__ . '/../includes/profile_change_helpers.php';
                $pending = get_pending_profile_request($mysqli, (int)$user_id);
                ?>

                <?php if ($pending): ?>
                  <div class="alert alert-warning mt-3">
                    <div class="fw-semibold">Awaiting Admin Approval</div>
                    <div class="small" style="opacity:.9;">
                      Requested: 
                      <?= h((string)$pending['requested_full_name']) ?> •
                      <?= h((string)$pending['requested_email']) ?> •
                      Age: <?= $pending['requested_age'] === null ? '—' : (int)$pending['requested_age'] ?>
                    </div>

                    <form method="post" action="<?= $BASE_URL ?>/cancel-profile-request.php" class="mt-2">
                      <button class="btn btn-sm btn-outline-light" name="cancel_id"
                              value="<?= (int)$pending['request_id'] ?>" type="submit">
                        Cancel Request
                      </button>
                    </form>
                  </div>
                <?php else: ?>
                  <a class="btn btn-outline-light mt-2"
                    href="<?= $BASE_URL ?>/<?= ($role === 'trainer') ? 'coach' : 'trainee' ?>/edit-profile.php">
                    Edit Profile
                  </a>
                <?php endif; ?>
            </div>
          </div>
        </div>
      </div>

      <div class="col-lg-7">
        <div class="row g-3">

          <div class="col-md-6">
            <div class="lr-card h-100">
              <div class="lr-card-body">
                <div class="lr-stat-label">Total reviews submitted</div>
                <div class="lr-stat-value mt-1"><?= (int)$total_reviews ?></div>
                <div class="lr-stat-subtext">Saved in expert_reviews.</div>
              </div>
            </div>
          </div>

          <div class="col-md-6">
            <div class="lr-card h-100">
              <div class="lr-card-body">
                <div class="lr-stat-label">Average rating given</div>
                <div class="lr-stat-value mt-1"><?= $total_reviews ? h(number_format($avg_rating, 2)) : '—' ?></div>
                <div class="lr-stat-subtext">Mean of your submitted ratings.</div>
              </div>
            </div>
          </div>

          <div class="col-12">
            <div class="lr-card">
              <div class="lr-card-header d-flex justify-content-between align-items-center">
                <div>
                  <div class="lr-section-title mb-1">Activity</div>
                  <div class="lr-section-heading mb-0">Latest review</div>
                </div>
                <a class="small text-decoration-none" href="<?= $BASE_URL ?>/coach/review-history.php">View history</a>
              </div>
              <div class="lr-card-body">
                <div class="lr-stat-subtext mb-0">
                  <?= $latest_review ? "Last submitted: " . h(fmtDT((string)$latest_review)) : "No reviews submitted yet." ?>
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

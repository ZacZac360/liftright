<?php
// liftright/web/trainee/profile.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['user']);
$page_title = "My Profile";

$user_id = (int)($_SESSION['user_id'] ?? 0);

require_once __DIR__ . '/../includes/profile_change_helpers.php';
$pending = get_pending_profile_request($mysqli, $user_id);

// Load user row (fresh from DB; don't rely only on session)
$stmt = $mysqli->prepare("
  SELECT user_id, full_name, email, role, age, created_at, last_login
  FROM users
  WHERE user_id = ?
  LIMIT 1
");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$user = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$user) {
  // very rare: session exists but user deleted
  header("Location: {$BASE_URL}/logout.php");
  exit;
}

// Stats: sessions
$stmt = $mysqli->prepare("
  SELECT
    COUNT(*) AS total_sessions,
    MAX(created_at) AS last_session_at,
    SUM(CASE WHEN reps_total > 0 THEN reps_good ELSE 0 END) AS sum_good,
    SUM(CASE WHEN reps_total > 0 THEN reps_total ELSE 0 END) AS sum_total,
    SUM(CASE WHEN fatigue_flag = 1 THEN 1 ELSE 0 END) AS fatigue_sessions
  FROM training_logs
  WHERE user_id = ?
");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$stats = $stmt->get_result()->fetch_assoc() ?: [];
$stmt->close();

$total_sessions   = (int)($stats['total_sessions'] ?? 0);
$last_session_at  = (string)($stats['last_session_at'] ?? '');
$sum_good         = (int)($stats['sum_good'] ?? 0);
$sum_total        = (int)($stats['sum_total'] ?? 0);
$fatigue_sessions = (int)($stats['fatigue_sessions'] ?? 0);

$avg_form_pct = ($sum_total > 0) ? (int)round(($sum_good / $sum_total) * 100) : 0;

function badgeForm(int $pct): string {
  if ($pct >= 85) return 'lr-badge lr-badge-good';
  if ($pct >= 70) return 'lr-badge lr-badge-warning';
  return 'lr-badge lr-badge-danger';
}
function fmtDT(?string $dt): string {
  if (!$dt) return "—";
  $ts = strtotime($dt);
  return $ts ? date("M d, Y • g:i A", $ts) : $dt;
}

// Latest SUS
$latest_sus = null;
$stmt = $mysqli->prepare("
  SELECT sus_score, created_at
  FROM sus_responses
  WHERE user_id = ?
  ORDER BY created_at DESC
  LIMIT 1
");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$latest_sus = $stmt->get_result()->fetch_assoc();
$stmt->close();

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

    <!-- Header -->
    <div class="row mb-4 align-items-center">
      <div class="col-md-8">
        <div class="lr-section-title mb-1">Account</div>
        <h1 class="lr-section-heading mb-1">My Profile</h1>
        <p class="lr-stat-subtext mb-0">View your account info and a quick summary of your LiftRight activity.</p>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0">
        <a class="btn btn-outline-light btn-sm" href="<?= $BASE_URL ?>/trainee/dashboard.php">Back to Dashboard</a>
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

      <!-- Profile Card -->
      <div class="col-lg-5">
        <div class="lr-card h-100">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">User</div>
            <div class="lr-section-heading mb-0">Profile details</div>
          </div>
          <div class="lr-card-body">
            <div class="d-flex align-items-center gap-3 mb-3">
              <div class="avatar-circle" style="width:56px;height:56px;font-size:18px;">
                <?= h(strtoupper(substr((string)$user['full_name'], 0, 1))) ?>
              </div>
              <div>
                <div class="fw-semibold fs-5"><?= h((string)$user['full_name']) ?></div>
                <div class="lr-stat-subtext"><?= h((string)$user['email']) ?></div>
              </div>
            </div>

            <div class="row g-3">
              <div class="col-6">
                <div class="lr-stat-label">Role</div>
                <div class="text-capitalize"><?= h((string)$user['role']) ?></div>
              </div>
              <div class="col-6">
                <div class="lr-stat-label">Age</div>
                <div><?= $user['age'] === null ? '—' : (int)$user['age'] ?></div>
              </div>

              <div class="col-12">
                <div class="lr-stat-label">Account created</div>
                <div><?= h(fmtDT((string)$user['created_at'])) ?></div>
              </div>
              <div class="col-12">
                <div class="lr-stat-label">Last login</div>
                <div><?= h(fmtDT((string)$user['last_login'])) ?></div>
              </div>
            </div>

            <hr class="border-secondary my-4">

            <div class="lr-stat-subtext mb-2">Quick actions</div>
            <div class="d-flex flex-wrap gap-2">
              <a class="btn btn-primary" href="<?= $BASE_URL ?>/trainee/start-session.php">Start Session</a>
              <a class="btn btn-outline-light" href="<?= $BASE_URL ?>/trainee/sessions.php">View Sessions</a>
              <a class="btn btn-outline-light" href="<?= $BASE_URL ?>/trainee/sus.php">Answer SUS</a>
            </div>

            <div class="small text-secondary mt-3" style="opacity:.85;">
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

      <!-- Activity Summary -->
      <div class="col-lg-7">
        <div class="row g-4">

          <div class="col-md-6">
            <div class="lr-card">
              <div class="lr-card-body">
                <div class="lr-stat-label">Total sessions</div>
                <div class="lr-stat-value"><?= (int)$total_sessions ?></div>
                <div class="lr-stat-subtext">Sessions saved to your account.</div>
              </div>
            </div>
          </div>

          <div class="col-md-6">
            <div class="lr-card">
              <div class="lr-card-body">
                <div class="lr-stat-label">Average form score</div>
                <div class="d-flex align-items-center gap-2">
                  <div class="lr-stat-value"><?= (int)$avg_form_pct ?>%</div>
                  <span class="<?= h(badgeForm($avg_form_pct)) ?>"><?= (int)$avg_form_pct ?>%</span>
                </div>
                <div class="lr-stat-subtext">Computed from reps_good / reps_total across sessions.</div>
              </div>
            </div>
          </div>

          <div class="col-md-6">
            <div class="lr-card">
              <div class="lr-card-body">
                <div class="lr-stat-label">Fatigue warnings</div>
                <div class="lr-stat-value"><?= (int)$fatigue_sessions ?></div>
                <div class="lr-stat-subtext">Number of sessions flagged as fatigue warning.</div>
              </div>
            </div>
          </div>

          <div class="col-md-6">
            <div class="lr-card">
              <div class="lr-card-body">
                <div class="lr-stat-label">Last session</div>
                <div class="lr-stat-value" style="font-size: 1.25rem;">
                  <?= h(fmtDT($last_session_at ?: null)) ?>
                </div>
                <div class="lr-stat-subtext">Most recent saved session timestamp.</div>
              </div>
            </div>
          </div>

          <!-- Latest SUS -->
          <div class="col-12">
            <div class="lr-card">
              <div class="lr-card-header d-flex justify-content-between align-items-center">
                <div>
                  <div class="lr-section-title mb-1">Evaluation</div>
                  <div class="lr-section-heading mb-0">Latest SUS response</div>
                </div>
                <a class="btn btn-sm btn-outline-light" href="<?= $BASE_URL ?>/trainee/sus.php">Open SUS</a>
              </div>
              <div class="lr-card-body">
                <?php if (!$latest_sus): ?>
                  <div class="lr-stat-subtext">No SUS submission yet. Answer the SUS questionnaire to help evaluate usability.</div>
                <?php else: ?>
                  <div class="d-flex flex-wrap align-items-center justify-content-between gap-2">
                    <div>
                      <div class="lr-stat-label">SUS score</div>
                      <div class="lr-stat-value"><?= h((string)$latest_sus['sus_score']) ?> / 100</div>
                      <div class="lr-stat-subtext"><?= h(fmtDT((string)$latest_sus['created_at'])) ?></div>
                    </div>
                    <span class="lr-badge lr-badge-good">SUS Saved</span>
                  </div>
                <?php endif; ?>
              </div>
            </div>
          </div>

        </div>
      </div>

    </div>

  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>

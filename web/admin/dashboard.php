<?php
// liftright/web/admin/dashboard.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['admin']);

$page_title = "Admin Dashboard";

/* ---------- Helpers ---------- */
if (!function_exists('h')) {
  function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
}
if (!function_exists('formatExercise')) {
  function formatExercise(string $ex): string {
    return match($ex) {
      'shoulder_press' => 'Shoulder Press',
      'bicep_curl'     => 'Bicep Curl',
      'lateral_raise'  => 'Lateral Raise',
      default          => ucwords(str_replace('_',' ', $ex)),
    };
  }
}
if (!function_exists('badgeForPct')) {
  function badgeForPct(int $pct): string {
    if ($pct >= 85) return 'lr-badge lr-badge-good';
    if ($pct >= 70) return 'lr-badge lr-badge-warning';
    return 'lr-badge lr-badge-danger';
  }
}

/* ---------- KPI Queries (admin = summaries only) ---------- */
$total_users = 0;
$sessions_today = 0;

$users_pending = 0;
$users_suspended = 0;

$profile_pending = 0;

$avg_accuracy_7d = 0;
$fatigue_rate_7d = 0;
$avg_processing_7d = 0;

$recent_activity = []; // aggregated view: NO user identity

// total users
$stmt = $mysqli->prepare("SELECT COUNT(*) AS c FROM users");
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();
$total_users = (int)($row['c'] ?? 0);

// sessions today
$stmt = $mysqli->prepare("
  SELECT COUNT(*) AS c
  FROM training_logs
  WHERE DATE(created_at) = CURDATE()
");
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();
$sessions_today = (int)($row['c'] ?? 0);

// users pending/suspended
$stmt = $mysqli->prepare("SELECT COUNT(*) AS c FROM users WHERE account_status = 'pending'");
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();
$users_pending = (int)($row['c'] ?? 0);

$stmt = $mysqli->prepare("SELECT COUNT(*) AS c FROM users WHERE account_status = 'suspended'");
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();
$users_suspended = (int)($row['c'] ?? 0);

// pending profile requests (use navbar helper if present, otherwise fallback)
$has_profile_requests = false;

if (isset($mysqli) && $mysqli instanceof mysqli) {
  if (function_exists('table_exists')) {
    $has_profile_requests = table_exists($mysqli, 'profile_change_requests');
  } else {
    $chk = $mysqli->prepare("
      SELECT 1
      FROM information_schema.tables
      WHERE table_schema = DATABASE() AND table_name = 'profile_change_requests'
      LIMIT 1
    ");
    $chk->execute();
    $has_profile_requests = ($chk->get_result()->num_rows > 0);
    $chk->close();
  }
}

if ($has_profile_requests) {
  $stmt = $mysqli->prepare("SELECT COUNT(*) AS c FROM profile_change_requests WHERE status = 'pending'");
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
  $stmt->close();
  $profile_pending = (int)($row['c'] ?? 0);
}

// last 7 days KPI (accuracy/fatigue/processing) — summaries only
$stmt = $mysqli->prepare("
  SELECT
    AVG(CASE WHEN reps_total > 0 THEN (reps_good / reps_total) * 100 ELSE NULL END) AS avg_accuracy,
    AVG(CASE WHEN fatigue_flag = 1 THEN 1 ELSE 0 END) AS fatigue_rate,
    AVG(processing_ms) AS avg_processing
  FROM training_logs
  WHERE created_at >= (NOW() - INTERVAL 7 DAY)
");
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

$avg_accuracy_7d   = (int)round((float)($row['avg_accuracy'] ?? 0));
$fatigue_rate_7d   = (int)round(((float)($row['fatigue_rate'] ?? 0)) * 100);
$avg_processing_7d = (int)round((float)($row['avg_processing'] ?? 0));

// recent activity (last 12 sessions) — NO user join / NO name/email
$stmt = $mysqli->prepare("
  SELECT
    log_id, exercise_type, reps_total, reps_good, fatigue_flag, created_at
  FROM training_logs
  ORDER BY created_at DESC
  LIMIT 12
");
$stmt->execute();
$res = $stmt->get_result();
while ($r = $res->fetch_assoc()) $recent_activity[] = $r;
$stmt->close();

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="lr-page-wrapper">
  <div class="container lr-main-container py-4">

    <!-- Header -->
    <div class="row mb-4 align-items-center">
      <div class="col-md-8">
        <div class="lr-section-title mb-1">System Overview</div>
        <h1 class="lr-section-heading mb-1">Admin Dashboard</h1>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0">
        <div class="d-flex gap-2 justify-content-md-end flex-wrap">
          <a class="btn btn-outline-light" href="<?= $BASE_URL ?>/admin/evaluation.php">
            <i class="fa-solid fa-chart-line me-2"></i>Evaluation
          </a>
          <a class="btn btn-outline-light" href="<?= $BASE_URL ?>/admin/exports.php">
            <i class="fa-solid fa-download me-2"></i>Exports
          </a>
        </div>
      </div>
    </div>

    <!-- Admin alerts / action tiles -->
    <div class="row g-3 mb-4">
      <div class="col-md-6 col-lg-3">
        <a class="lr-card h-100 d-block text-decoration-none" href="<?= $BASE_URL ?>/admin/users.php?status=pending">
          <div class="lr-card-body">
            <div class="lr-stat-label">Pending approvals</div>
            <div class="lr-stat-value mt-1"><?= (int)$users_pending ?></div>
            <div class="lr-stat-subtext">Accounts awaiting approval.</div>
          </div>
        </a>
      </div>

      <div class="col-md-6 col-lg-3">
        <a class="lr-card h-100 d-block text-decoration-none" href="<?= $BASE_URL ?>/admin/users.php?status=suspended">
          <div class="lr-card-body">
            <div class="lr-stat-label">Suspended accounts</div>
            <div class="lr-stat-value mt-1"><?= (int)$users_suspended ?></div>
            <div class="lr-stat-subtext">Accounts blocked from login.</div>
          </div>
        </a>
      </div>

      <div class="col-md-6 col-lg-3">
        <a class="lr-card h-100 d-block text-decoration-none" href="<?= $BASE_URL ?>/admin/profile-requests.php?status=pending">
          <div class="lr-card-body">
            <div class="lr-stat-label">Profile requests</div>
            <div class="lr-stat-value mt-1"><?= (int)$profile_pending ?></div>
            <div class="lr-stat-subtext">Pending change requests.</div>
          </div>
        </a>
      </div>

      <div class="col-md-6 col-lg-3">
        <a class="lr-card h-100 d-block text-decoration-none" href="<?= $BASE_URL ?>/admin/thresholds.php">
          <div class="lr-card-body">
            <div class="lr-stat-label">System tuning</div>
            <div class="lr-stat-value mt-1"><i class="fa-solid fa-sliders"></i></div>
            <div class="lr-stat-subtext">Thresholds & sensitivity.</div>
          </div>
        </a>
      </div>
    </div>

    <!-- Core KPI cards -->
    <div class="row g-3 mb-4">
      <div class="col-md-6 col-lg-3">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Total users</div>
            <div class="lr-stat-value mt-1"><?= (int)$total_users ?></div>
            <div class="lr-stat-subtext">All roles (trainee / trainer / admin).</div>
          </div>
        </div>
      </div>

      <div class="col-md-6 col-lg-3">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Sessions today</div>
            <div class="lr-stat-value mt-1"><?= (int)$sessions_today ?></div>
            <div class="lr-stat-subtext">Based on <code>training_logs.created_at</code>.</div>
          </div>
        </div>
      </div>

      <div class="col-md-6 col-lg-3">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Avg accuracy (7d)</div>
            <div class="lr-stat-value mt-1"><?= (int)$avg_accuracy_7d ?>%</div>
            <div class="lr-stat-subtext">Mean of per-session good/total reps.</div>
          </div>
        </div>
      </div>

      <div class="col-md-6 col-lg-3">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Fatigue rate (7d)</div>
            <div class="lr-stat-value mt-1"><?= (int)$fatigue_rate_7d ?>%</div>
            <div class="lr-stat-subtext">Sessions flagged fatigue.</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Secondary KPIs + quick actions -->
    <div class="row g-3 mb-4">
      <div class="col-lg-8">
        <div class="lr-card h-100">
          <div class="lr-card-header d-flex justify-content-between align-items-center">
            <div>
              <div class="lr-section-title mb-1">Admin</div>
              <div class="lr-section-heading mb-0">Quick actions</div>
            </div>
          </div>

          <div class="lr-card-body">
            <div class="d-flex flex-wrap gap-2">
              <a class="btn btn-primary btn-sm" href="<?= $BASE_URL ?>/admin/users.php">
                <i class="fa-solid fa-users me-2"></i>Manage Users
              </a>
              <a class="btn btn-outline-light btn-sm" href="<?= $BASE_URL ?>/admin/profile-requests.php">
                <i class="fa-solid fa-id-card me-2"></i>Profile Requests
              </a>
              <a class="btn btn-outline-light btn-sm" href="<?= $BASE_URL ?>/admin/evaluation.php">
                <i class="fa-solid fa-chart-line me-2"></i>Evaluation Summary
              </a>
              <a class="btn btn-outline-light btn-sm" href="<?= $BASE_URL ?>/admin/thresholds.php">
                <i class="fa-solid fa-sliders me-2"></i>Thresholds
              </a>
              <a class="btn btn-outline-light btn-sm" href="<?= $BASE_URL ?>/admin/models.php">
                <i class="fa-solid fa-cubes me-2"></i>Models
              </a>
              <a class="btn btn-outline-light btn-sm" href="<?= $BASE_URL ?>/admin/exports.php">
                <i class="fa-solid fa-file-export me-2"></i>Exports
              </a>
            </div>

            <div class="lr-stat-subtext mt-3 mb-0">
            </div>
          </div>
        </div>
      </div>

      <div class="col-lg-4">
        <div class="lr-card h-100">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">Performance</div>
            <div class="lr-section-heading mb-0">Avg processing (7d)</div>
          </div>
          <div class="lr-card-body">
            <div class="lr-stat-value"><?= (int)$avg_processing_7d ?> ms</div>
            <div class="lr-stat-subtext mb-0">Mean pipeline time per session.</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Recent activity (aggregate-safe) -->
    <div class="lr-card">
      <div class="lr-card-header d-flex justify-content-between align-items-center">
        <div>
          <div class="lr-section-title mb-1">Activity</div>
          <div class="lr-section-heading mb-0">Recent session summaries</div>
        </div>
        <div class="lr-stat-subtext mb-0">Last 12 sessions (no user identity)</div>
      </div>

      <div class="lr-card-body p-0">
        <div class="table-responsive">
          <table class="table table-hover table-striped align-middle mb-0 table-lr-dark">
            <thead>
              <tr>
                <th>Date</th>
                <th>Exercise</th>
                <th>Reps</th>
                <th>Accuracy</th>
                <th>Fatigue</th>
                <th class="text-end">Log ID</th>
              </tr>
            </thead>
            <tbody>
            <?php if (count($recent_activity) === 0): ?>
              <tr>
                <td colspan="6" class="text-center py-4 lr-stat-subtext">No activity found yet.</td>
              </tr>
            <?php else: ?>
              <?php foreach ($recent_activity as $r):
                $total = (int)$r['reps_total'];
                $good  = (int)$r['reps_good'];
                $pct   = ($total > 0) ? (int)round(($good / $total) * 100) : 0;
                $fat   = ((int)$r['fatigue_flag'] === 1);
              ?>
                <tr>
                  <td><?= h(date("M d, Y • g:i A", strtotime((string)$r['created_at']))) ?></td>
                  <td><span class="lr-chip-exercise"><?= h(formatExercise((string)$r['exercise_type'])) ?></span></td>
                  <td><?= (int)$good ?> good / <?= (int)$total ?> total</td>
                  <td>
                    <?php if ($total <= 0): ?>
                      <span class="lr-stat-subtext">—</span>
                    <?php else: ?>
                      <span class="<?= h(badgeForPct($pct)) ?>"><?= (int)$pct ?>%</span>
                    <?php endif; ?>
                  </td>
                  <td>
                    <span class="<?= $fat ? 'lr-badge lr-badge-warning' : 'lr-badge lr-badge-good' ?>">
                      <?= $fat ? 'Warning' : 'Normal' ?>
                    </span>
                  </td>
                  <td class="text-end"><span class="lr-stat-subtext">#<?= (int)$r['log_id'] ?></span></td>
                </tr>
              <?php endforeach; ?>
            <?php endif; ?>
            </tbody>
          </table>
        </div>
      </div>

      <div class="lr-card-body">
      </div>
    </div>

  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>
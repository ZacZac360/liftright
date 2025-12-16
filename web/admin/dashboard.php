<?php
// liftright/web/admin/dashboard.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['admin']);

$page_title = "Admin Dashboard";

function formatExercise(string $ex): string {
  return match($ex) {
    'shoulder_press' => 'Shoulder Press',
    'bicep_curl'     => 'Bicep Curl',
    'lateral_raise'  => 'Lateral Raise',
    default          => ucwords(str_replace('_',' ', $ex)),
  };
}

function badgeForPct(int $pct): string {
  if ($pct >= 85) return 'lr-badge lr-badge-good';
  if ($pct >= 70) return 'lr-badge lr-badge-warning';
  return 'lr-badge lr-badge-danger';
}

$total_users = 0;
$sessions_today = 0;

// total users
$stmt = $mysqli->prepare("SELECT COUNT(*) AS c FROM users");
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();
$total_users = (int)($row['c'] ?? 0);

// sessions processed today (by created_at date)
$stmt = $mysqli->prepare("
  SELECT COUNT(*) AS c
  FROM training_logs
  WHERE DATE(created_at) = CURDATE()
");
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();
$sessions_today = (int)($row['c'] ?? 0);

// "average pose accuracy of each report" -> per-log accuracy% = reps_good/reps_total*100
$recent_reports = [];
$stmt = $mysqli->prepare("
  SELECT
    l.log_id, l.exercise_type, l.reps_total, l.reps_good, l.reps_bad, l.fatigue_flag, l.created_at,
    u.full_name
  FROM training_logs l
  JOIN users u ON u.user_id = l.user_id
  ORDER BY l.created_at DESC
  LIMIT 12
");
$stmt->execute();
$res = $stmt->get_result();
while ($r = $res->fetch_assoc()) $recent_reports[] = $r;
$stmt->close();

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="lr-page-wrapper">
  <div class="container lr-main-container py-4">

    <div class="row mb-4 align-items-center">
      <div class="col-md-8">
        <div class="lr-section-title mb-1">System Overview</div>
        <h1 class="lr-section-heading mb-1">Admin Dashboard</h1>
        <p class="lr-stat-subtext mb-0">Monitor platform usage, report accuracy, and system health.</p>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0">
        <a class="btn btn-outline-light" href="<?= $BASE_URL ?>/admin/exports.php">
          <i class="fa-solid fa-download me-2"></i>Exports
        </a>
      </div>
    </div>

    <div class="row g-3 mb-4">
      <div class="col-md-6 col-lg-4">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Total users</div>
            <div class="lr-stat-value mt-1"><?= (int)$total_users ?></div>
            <div class="lr-stat-subtext">All roles (trainee / coach / admin).</div>
          </div>
        </div>
      </div>

      <div class="col-md-6 col-lg-4">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Sessions processed today</div>
            <div class="lr-stat-value mt-1"><?= (int)$sessions_today ?></div>
            <div class="lr-stat-subtext">Based on <code>training_logs.created_at</code>.</div>
          </div>
        </div>
      </div>

      <div class="col-md-12 col-lg-4">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Quick actions</div>
            <div class="d-flex flex-wrap gap-2 mt-2">
              <a class="btn btn-primary btn-sm" href="<?= $BASE_URL ?>/admin/users.php">
                <i class="fa-solid fa-users me-2"></i>Manage Users
              </a>
              <a class="btn btn-outline-light btn-sm" href="<?= $BASE_URL ?>/admin/thresholds.php">
                <i class="fa-solid fa-sliders me-2"></i>Error Thresholds
              </a>
              <a class="btn btn-outline-light btn-sm" href="<?= $BASE_URL ?>/admin/exports.php">
                <i class="fa-solid fa-file-export me-2"></i>Export Data
              </a>
            </div>
            <div class="lr-stat-subtext mt-2">Prototype-safe: no fancy admin workflows.</div>
          </div>
        </div>
      </div>
    </div>

    <div class="lr-card">
      <div class="lr-card-header">
        <div class="lr-section-title mb-1">Reports</div>
        <div class="lr-section-heading mb-0">Recent session accuracy (per report)</div>
      </div>

      <div class="lr-card-body p-0">
        <div class="table-responsive">
          <table class="table table-hover table-striped align-middle mb-0 table-lr-dark">
            <thead>
              <tr>
                <th>Date</th>
                <th>User</th>
                <th>Exercise</th>
                <th>Reps</th>
                <th>Accuracy</th>
                <th>Fatigue</th>
              </tr>
            </thead>
            <tbody>
            <?php if (count($recent_reports) === 0): ?>
              <tr>
                <td colspan="6" class="text-center py-4 lr-stat-subtext">No reports found yet.</td>
              </tr>
            <?php else: ?>
              <?php foreach ($recent_reports as $r):
                $total = (int)$r['reps_total'];
                $good  = (int)$r['reps_good'];
                $pct   = ($total > 0) ? (int)round(($good / $total) * 100) : 0;
              ?>
                <tr>
                  <td><?= h(date("M d, Y • g:i A", strtotime((string)$r['created_at']))) ?></td>
                  <td><?= h((string)$r['full_name']) ?></td>
                  <td><span class="lr-chip-exercise"><?= h(formatExercise((string)$r['exercise_type'])) ?></span></td>
                  <td><?= (int)$good ?> good / <?= (int)$total ?> total</td>
                  <td><span class="<?= h(badgeForPct($pct)) ?>"><?= (int)$pct ?>%</span></td>
                  <td>
                    <span class="<?= ((int)$r['fatigue_flag'] === 1) ? 'lr-badge lr-badge-warning' : 'lr-badge lr-badge-good' ?>">
                      <?= ((int)$r['fatigue_flag'] === 1) ? 'Warning' : 'Normal' ?>
                    </span>
                  </td>
                </tr>
              <?php endforeach; ?>
            <?php endif; ?>
            </tbody>
          </table>
        </div>
      </div>
    </div>

  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>

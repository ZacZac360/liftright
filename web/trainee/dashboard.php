<?php
// liftright/web/trainee/dashboard.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['user']); // schema role is 'user', not 'trainee'

$page_title = "Trainee Dashboard";

$user_id   = (int)$_SESSION['user_id'];
$full_name = (string)$_SESSION['full_name'];

// 1) Aggregate stats from training_logs
$total_sessions = 0;
$avg_form = 0;         // computed from reps_good / reps_total across all logs
$latest_date = null;

$stmt = $mysqli->prepare("
  SELECT
    COUNT(*) AS c,
    SUM(reps_good) AS sum_good,
    SUM(reps_total) AS sum_total,
    MAX(created_at) AS latest
  FROM training_logs
  WHERE user_id = ?
");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

if ($row) {
  $total_sessions = (int)($row['c'] ?? 0);
  $sum_good = (int)($row['sum_good'] ?? 0);
  $sum_total = (int)($row['sum_total'] ?? 0);
  $avg_form = ($sum_total > 0) ? (int)round(($sum_good / $sum_total) * 100) : 0;
  $latest_date = $row['latest'] ?? null;
}

// 2) Recent sessions (limit 5)
$recent_sessions = [];
$stmt = $mysqli->prepare("
  SELECT
    log_id, exercise_type, reps_total, reps_good, reps_bad, fatigue_flag, created_at
  FROM training_logs
  WHERE user_id = ?
  ORDER BY created_at DESC
  LIMIT 5
");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$res = $stmt->get_result();
while ($r = $res->fetch_assoc()) $recent_sessions[] = $r;
$stmt->close();

function formatExercise(string $ex): string {
  return match($ex) {
    'shoulder_press' => 'Shoulder Press',
    'bicep_curl'     => 'Bicep Curl',
    'lateral_raise'  => 'Lateral Raise',
    default          => ucwords(str_replace('_',' ', $ex)),
  };
}

function formBadge(int $pct): string {
  if ($pct >= 85) return 'lr-badge lr-badge-good';
  if ($pct >= 70) return 'lr-badge lr-badge-warning';
  return 'lr-badge lr-badge-danger';
}

function fatigueBadge(int $flag): string {
  return $flag ? 'lr-badge lr-badge-warning' : 'lr-badge lr-badge-good';
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
        <div class="lr-section-title mb-1">Trainee Overview</div>
        <h1 class="lr-section-heading mb-1">Welcome back, <?= h($full_name) ?> 👋</h1>
        <p class="lr-stat-subtext mb-0">
          Here’s a snapshot of your recent training quality and fatigue patterns.
        </p>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0">
        <a class="btn btn-primary px-3" href="<?= $BASE_URL ?>/trainee/start-session.php">
          Start New Session
        </a>
      </div>
    </div>

    <!-- Stats -->
    <div class="row g-3 mb-4">
      <div class="col-md-4">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Total sessions</div>
            <div class="lr-stat-value mt-1"><?= (int)$total_sessions ?></div>
            <p class="lr-stat-subtext mb-0">Based on recorded AI-assessed workouts.</p>
          </div>
        </div>
      </div>

      <div class="col-md-4">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Average form score</div>
            <div class="lr-stat-value mt-1"><?= (int)$avg_form ?>%</div>
            <span class="<?= h(formBadge($avg_form)) ?> mt-2">
              <?= $avg_form >= 85 ? 'Good overall form' : ($avg_form >= 70 ? 'Moderate — room to improve' : 'Needs attention') ?>
            </span>
          </div>
        </div>
      </div>

      <div class="col-md-4">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Last recorded session</div>
            <div class="lr-stat-value mt-1">
              <?= $latest_date ? h(date("M d, Y", strtotime((string)$latest_date))) : '—' ?>
            </div>
            <p class="lr-stat-subtext mb-0">Train consistently to see clearer fatigue trends.</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Content -->
    <div class="row g-4">

      <!-- Recent sessions table -->
      <div class="col-lg-7">
        <div class="lr-card h-100">
          <div class="lr-card-header d-flex justify-content-between align-items-center">
            <div>
              <div class="lr-section-title mb-1">History</div>
              <div class="lr-section-heading mb-0">Recent Sessions</div>
            </div>
            <a href="<?= $BASE_URL ?>/trainee/sessions.php" class="small text-decoration-none">View all</a>
          </div>

          <div class="lr-card-body p-0">
            <div class="table-responsive">
              <table class="table table-hover table-striped align-middle mb-0 table-lr-dark">
                <thead>
                  <tr>
                    <th>Date</th>
                    <th>Exercise</th>
                    <th>Reps</th>
                    <th>Form</th>
                    <th>Fatigue</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                <?php if (count($recent_sessions) === 0): ?>
                  <tr>
                    <td colspan="6" class="text-center py-4 lr-stat-subtext">No recorded sessions yet.</td>
                  </tr>
                <?php else: ?>
                  <?php foreach ($recent_sessions as $sess): 
                    $total = (int)$sess['reps_total'];
                    $good  = (int)$sess['reps_good'];
                    $pct   = ($total > 0) ? (int)round(($good / $total) * 100) : 0;
                  ?>
                    <tr>
                      <td><?= h(date("M d, Y", strtotime((string)$sess['created_at']))) ?></td>
                      <td><span class="lr-chip-exercise"><?= h(formatExercise((string)$sess['exercise_type'])) ?></span></td>
                      <td><?= (int)$sess['reps_good'] ?> good / <?= (int)$sess['reps_total'] ?> total</td>
                      <td><span class="<?= h(formBadge($pct)) ?>"><?= (int)$pct ?>%</span></td>
                      <td>
                        <span class="<?= h(fatigueBadge((int)$sess['fatigue_flag'])) ?>">
                          <?= ((int)$sess['fatigue_flag'] === 1) ? 'Warning' : 'Normal' ?>
                        </span>
                      </td>
                      <td class="text-end">
                        <a class="btn btn-sm btn-outline-light"
                           href="<?= $BASE_URL ?>/trainee/session-view.php?log_id=<?= (int)$sess['log_id'] ?>">
                          View
                        </a>
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

      <!-- Chart + tips -->
      <div class="col-lg-5">

        <div class="lr-card mb-3">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">Trend</div>
            <div class="lr-section-heading mb-0">Form consistency (last 10 sessions)</div>
          </div>
          <div class="lr-card-body">
            <div class="position-relative" style="height:220px;">
            <canvas id="lrFormTrendChart"></canvas>
            </div>
            <div class="lr-stat-subtext mt-2">
            Showing your last 10 sessions. Higher is better (good reps / total reps).
            </div>
          </div>
        </div>

        <div class="lr-card">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">Guidance</div>
            <div class="lr-section-heading mb-0">Key reminders for your next sessions</div>
          </div>
          <div class="lr-card-body">
            <ul class="lr-stat-subtext mb-0">
              <li>Stop if form drops significantly for multiple reps.</li>
              <li>Control tempo when fatigue indicators rise.</li>
              <li>For lateral raises: avoid shrugging and excessive sway.</li>
            </ul>
          </div>
        </div>

      </div>
    </div>

  </div>
</div>

<script>
  window.LR_DASHBOARD = {
    trendUrl: "<?= $BASE_URL ?>/api/dashboard_trend.php"
  };
</script>

<?php require __DIR__ . '/../includes/footer.php'; ?>

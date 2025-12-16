<?php
// liftright/web/coach/dashboard.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['trainer']);

$page_title = "Coach Dashboard";

$trainer_id = (int)($_SESSION['user_id'] ?? 0);
$full_name  = (string)($_SESSION['full_name'] ?? 'Coach');

// --- Helpers ---
function formatExercise(string $ex): string {
  return match($ex) {
    'shoulder_press' => 'Shoulder Press',
    'bicep_curl'     => 'Bicep Curl',
    'lateral_raise'  => 'Lateral Raise',
    default          => ucwords(str_replace('_',' ', $ex)),
  };
}
function formPct(int $good, int $total): int {
  return ($total > 0) ? (int)round(($good / $total) * 100) : 0;
}
function formBadge(int $pct): string {
  if ($pct >= 85) return 'lr-badge lr-badge-good';
  if ($pct >= 70) return 'lr-badge lr-badge-warning';
  return 'lr-badge lr-badge-danger';
}
function fatigueBadge(int $flag): string {
  return $flag ? 'lr-badge lr-badge-warning' : 'lr-badge lr-badge-good';
}
function reviewedBadge(bool $reviewed): string {
  return $reviewed ? 'lr-badge lr-badge-good' : 'lr-badge lr-badge-warning';
}

// --- 1) Global overview stats ---
$stats = [
  'total_sessions' => 0,
  'total_users' => 0,
  'avg_form' => 0,
  'fatigue_sessions' => 0,
  'avg_latency_ms' => null,
  'pending_reviews' => 0,
];

$stmt = $mysqli->prepare("
  SELECT
    COUNT(*) AS total_sessions,
    COUNT(DISTINCT user_id) AS total_users,
    SUM(reps_good) AS sum_good,
    SUM(reps_total) AS sum_total,
    SUM(CASE WHEN fatigue_flag = 1 THEN 1 ELSE 0 END) AS fatigue_sessions,
    AVG(processing_ms) AS avg_latency_ms
  FROM training_logs
");
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

if ($row) {
  $stats['total_sessions']   = (int)($row['total_sessions'] ?? 0);
  $stats['total_users']      = (int)($row['total_users'] ?? 0);
  $sum_good                  = (int)($row['sum_good'] ?? 0);
  $sum_total                 = (int)($row['sum_total'] ?? 0);
  $stats['avg_form']         = ($sum_total > 0) ? (int)round(($sum_good / $sum_total) * 100) : 0;
  $stats['fatigue_sessions'] = (int)($row['fatigue_sessions'] ?? 0);
  $stats['avg_latency_ms']   = ($row['avg_latency_ms'] === null) ? null : (int)round((float)$row['avg_latency_ms']);
}

// Pending reviews = sessions with no expert_reviews at all
$stmt = $mysqli->prepare("
  SELECT COUNT(*) AS pending
  FROM training_logs tl
  LEFT JOIN expert_reviews er ON er.log_id = tl.log_id
  WHERE er.review_id IS NULL
");
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

$stats['pending_reviews'] = (int)($row['pending'] ?? 0);

// --- 2) Recent sessions (system-wide) ---
$recent = [];
$stmt = $mysqli->prepare("
  SELECT
    tl.log_id,
    tl.created_at,
    tl.exercise_type,
    tl.source_type,
    tl.reps_total,
    tl.reps_good,
    tl.reps_bad,
    tl.fatigue_flag,
    tl.processing_ms,
    u.full_name AS trainee_name,
    u.user_id AS trainee_id,
    EXISTS(
      SELECT 1 FROM expert_reviews er
      WHERE er.log_id = tl.log_id
      LIMIT 1
    ) AS is_reviewed
  FROM training_logs tl
  JOIN users u ON u.user_id = tl.user_id
  ORDER BY tl.created_at DESC
  LIMIT 10
");
$stmt->execute();
$res = $stmt->get_result();
while ($r = $res->fetch_assoc()) $recent[] = $r;
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
        <div class="lr-section-title mb-1">Coach Overview</div>
        <h1 class="lr-section-heading mb-1">Welcome, <?= h($full_name) ?> 👋</h1>
        <p class="lr-stat-subtext mb-0">Monitor trainee sessions and review AI results for Objective 5.</p>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0">
        <a class="btn btn-primary px-3" href="<?= $BASE_URL ?>/coach/reviews.php">
        Open Reviews
        </a>
      </div>
    </div>

    <!-- Stats -->
    <div class="row g-3 mb-4">
      <div class="col-md-3">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Total sessions</div>
            <div class="lr-stat-value mt-1"><?= (int)$stats['total_sessions'] ?></div>
            <div class="lr-stat-subtext mb-0">System-wide logs.</div>
          </div>
        </div>
      </div>

      <div class="col-md-3">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Active trainees</div>
            <div class="lr-stat-value mt-1"><?= (int)$stats['total_users'] ?></div>
            <div class="lr-stat-subtext mb-0">Users with recorded sessions.</div>
          </div>
        </div>
      </div>

      <div class="col-md-3">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Average form score</div>
            <div class="d-flex align-items-center gap-2 mt-1">
              <div class="lr-stat-value"><?= (int)$stats['avg_form'] ?>%</div>
              <span class="<?= h(formBadge((int)$stats['avg_form'])) ?>"><?= (int)$stats['avg_form'] ?>%</span>
            </div>
            <div class="lr-stat-subtext mb-0">From reps_good / reps_total.</div>
          </div>
        </div>
      </div>

      <div class="col-md-3">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Pending reviews</div>
            <div class="lr-stat-value mt-1"><?= (int)$stats['pending_reviews'] ?></div>
            <div class="lr-stat-subtext mb-0">Sessions without any expert review.</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Secondary stats -->
    <div class="row g-3 mb-4">
      <div class="col-md-6">
        <div class="lr-card">
          <div class="lr-card-body d-flex justify-content-between align-items-center">
            <div>
              <div class="lr-stat-label">Fatigue-flagged sessions</div>
              <div class="lr-stat-subtext mb-0">Count of sessions where fatigue_flag = 1</div>
            </div>
            <span class="lr-badge lr-badge-warning"><?= (int)$stats['fatigue_sessions'] ?></span>
          </div>
        </div>
      </div>
      <div class="col-md-6">
        <div class="lr-card">
          <div class="lr-card-body d-flex justify-content-between align-items-center">
            <div>
              <div class="lr-stat-label">Average processing latency</div>
              <div class="lr-stat-subtext mb-0">Objective 5: system responsiveness</div>
            </div>
            <span class="lr-badge lr-badge-good">
              <?= $stats['avg_latency_ms'] === null ? '—' : h((string)$stats['avg_latency_ms'] . ' ms') ?>
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- Recent Sessions -->
    <div class="lr-card">
      <div class="lr-card-header d-flex justify-content-between align-items-center">
        <div>
          <div class="lr-section-title mb-1">Latest activity</div>
          <div class="lr-section-heading mb-0">Recent sessions (system-wide)</div>
        </div>
        <div class="lr-stat-subtext mb-0"><?= count($recent) ?> shown</div>
      </div>

      <div class="lr-card-body p-0">
        <div class="table-responsive">
          <table class="table table-hover table-striped align-middle mb-0 table-lr-dark">
            <thead>
              <tr>
                <th>Date</th>
                <th>Trainee</th>
                <th>Exercise</th>
                <th>Reps</th>
                <th>Form</th>
                <th>Fatigue</th>
                <th>Review</th>
                <th class="text-end">Latency</th>
              </tr>
            </thead>
            <tbody>
              <?php if (!$recent): ?>
                <tr>
                  <td colspan="8" class="text-center py-4 lr-stat-subtext">No sessions found yet.</td>
                </tr>
              <?php else: ?>
                <?php foreach ($recent as $s):
                  $total = (int)$s['reps_total'];
                  $good  = (int)$s['reps_good'];
                  $pct   = formPct($good, $total);
                  $reviewed = ((int)$s['is_reviewed'] === 1);
                ?>
                  <tr>
                    <td><?= h(date("M d, Y • g:i A", strtotime((string)$s['created_at']))) ?></td>
                    <td><?= h((string)$s['trainee_name']) ?></td>
                    <td><span class="lr-chip-exercise"><?= h(formatExercise((string)$s['exercise_type'])) ?></span></td>
                    <td><?= (int)$good ?> good / <?= (int)$total ?> total</td>
                    <td><span class="<?= h(formBadge($pct)) ?>"><?= (int)$pct ?>%</span></td>
                    <td>
                      <span class="<?= h(fatigueBadge((int)$s['fatigue_flag'])) ?>">
                        <?= ((int)$s['fatigue_flag'] === 1) ? 'Warning' : 'Normal' ?>
                      </span>
                    </td>
                    <td>
                      <span class="<?= h(reviewedBadge($reviewed)) ?>">
                        <?= $reviewed ? 'Reviewed' : 'Pending' ?>
                      </span>
                    </td>
                    <td class="text-end">
                      <?= $s['processing_ms'] === null ? '—' : h((string)$s['processing_ms'] . ' ms') ?>
                    </td>
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

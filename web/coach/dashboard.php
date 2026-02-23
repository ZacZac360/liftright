<?php
// liftright/web/coach/dashboard.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['trainer']);

$page_title = "Coach Dashboard";

$trainer_id = (int)($_SESSION['user_id'] ?? 0);
$full_name  = (string)($_SESSION['full_name'] ?? 'Coach');

/* ---------- Helpers ---------- */
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

/* ---------- 0) Load my trainees (for selector + validation) ---------- */
$trainees = [];
$stmt = $mysqli->prepare("
  SELECT user_id, full_name, email
  FROM users
  WHERE role = 'user' AND trainer_id = ?
  ORDER BY full_name ASC
");
$stmt->bind_param("i", $trainer_id);
$stmt->execute();
$res = $stmt->get_result();
while ($r = $res->fetch_assoc()) $trainees[] = $r;
$stmt->close();

$allowed_trainee_ids = array_map(fn($t) => (int)$t['user_id'], $trainees);

$selected_trainee_id = isset($_GET['trainee_id']) ? (int)$_GET['trainee_id'] : 0;
if ($selected_trainee_id > 0 && !in_array($selected_trainee_id, $allowed_trainee_ids, true)) {
  // invalid / not assigned to this coach -> reset
  $selected_trainee_id = 0;
}

$selected_trainee = null;
if ($selected_trainee_id > 0) {
  foreach ($trainees as $t) {
    if ((int)$t['user_id'] === $selected_trainee_id) { $selected_trainee = $t; break; }
  }
}

/* ---------- 1) Overview stats (All trainees OR Selected trainee) ---------- */
$stats = [
  'total_sessions' => 0,
  'total_users' => 0,
  'avg_form' => 0,
  'fatigue_sessions' => 0,
  'avg_latency_ms' => null,
  'pending_reviews' => 0,
];

if ($selected_trainee_id > 0) {
  // Stats for ONE trainee
  $stmt = $mysqli->prepare("
    SELECT
      COUNT(*) AS total_sessions,
      COUNT(DISTINCT tl.user_id) AS total_users,
      SUM(tl.reps_good) AS sum_good,
      SUM(tl.reps_total) AS sum_total,
      SUM(CASE WHEN tl.fatigue_flag = 1 THEN 1 ELSE 0 END) AS fatigue_sessions,
      AVG(tl.processing_ms) AS avg_latency_ms
    FROM training_logs tl
    JOIN users u ON u.user_id = tl.user_id
    WHERE u.trainer_id = ?
      AND tl.user_id = ?
  ");
  $stmt->bind_param("ii", $trainer_id, $selected_trainee_id);
} else {
  // Stats for ALL assigned trainees
  $stmt = $mysqli->prepare("
    SELECT
      COUNT(*) AS total_sessions,
      COUNT(DISTINCT tl.user_id) AS total_users,
      SUM(tl.reps_good) AS sum_good,
      SUM(tl.reps_total) AS sum_total,
      SUM(CASE WHEN tl.fatigue_flag = 1 THEN 1 ELSE 0 END) AS fatigue_sessions,
      AVG(tl.processing_ms) AS avg_latency_ms
    FROM training_logs tl
    JOIN users u ON u.user_id = tl.user_id
    WHERE u.trainer_id = ?
  ");
  $stmt->bind_param("i", $trainer_id);
}

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

/* ---------- 2) Pending reviews (mine) ---------- */
if ($selected_trainee_id > 0) {
  $stmt = $mysqli->prepare("
    SELECT COUNT(*) AS pending
    FROM training_logs tl
    JOIN users u ON u.user_id = tl.user_id
    LEFT JOIN expert_reviews er
      ON er.log_id = tl.log_id AND er.trainer_id = ?
    WHERE u.trainer_id = ?
      AND tl.user_id = ?
      AND er.review_id IS NULL
  ");
  $stmt->bind_param("iii", $trainer_id, $trainer_id, $selected_trainee_id);
} else {
  $stmt = $mysqli->prepare("
    SELECT COUNT(*) AS pending
    FROM training_logs tl
    JOIN users u ON u.user_id = tl.user_id
    LEFT JOIN expert_reviews er
      ON er.log_id = tl.log_id AND er.trainer_id = ?
    WHERE u.trainer_id = ?
      AND er.review_id IS NULL
  ");
  $stmt->bind_param("ii", $trainer_id, $trainer_id);
}
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();
$stats['pending_reviews'] = (int)($row['pending'] ?? 0);

/* ---------- 3) Per-trainee summary list (only when viewing ALL) ---------- */
$trainee_summary = [];
if ($selected_trainee_id === 0 && count($trainees) > 0) {
  // summary per trainee (last 30 days is a nice “dashboard” horizon, but we’ll keep it all-time simple)
  $stmt = $mysqli->prepare("
    SELECT
      u.user_id,
      u.full_name,
      COUNT(tl.log_id) AS sessions,
      SUM(tl.reps_good) AS sum_good,
      SUM(tl.reps_total) AS sum_total,
      SUM(CASE WHEN tl.fatigue_flag = 1 THEN 1 ELSE 0 END) AS fatigue_sessions,
      SUM(CASE WHEN er.review_id IS NULL THEN 1 ELSE 0 END) AS pending_reviews
    FROM users u
    LEFT JOIN training_logs tl ON tl.user_id = u.user_id
    LEFT JOIN expert_reviews er
      ON er.log_id = tl.log_id AND er.trainer_id = ?
    WHERE u.role = 'user'
      AND u.trainer_id = ?
    GROUP BY u.user_id, u.full_name
    ORDER BY u.full_name ASC
  ");
  $stmt->bind_param("ii", $trainer_id, $trainer_id);
  $stmt->execute();
  $res = $stmt->get_result();
  while ($r = $res->fetch_assoc()) $trainee_summary[] = $r;
  $stmt->close();
}

/* ---------- 4) Recent sessions (all or selected trainee) ---------- */
$recent = [];

if ($selected_trainee_id > 0) {
  $stmt = $mysqli->prepare("
    SELECT
      tl.log_id,
      tl.created_at,
      tl.exercise_type,
      tl.reps_total,
      tl.reps_good,
      tl.fatigue_flag,
      tl.processing_ms,
      u.full_name AS trainee_name,
      EXISTS(
        SELECT 1 FROM expert_reviews er
        WHERE er.log_id = tl.log_id
          AND er.trainer_id = ?
        LIMIT 1
      ) AS is_reviewed
    FROM training_logs tl
    JOIN users u ON u.user_id = tl.user_id
    WHERE u.trainer_id = ?
      AND tl.user_id = ?
    ORDER BY tl.created_at DESC
    LIMIT 12
  ");
  $stmt->bind_param("iii", $trainer_id, $trainer_id, $selected_trainee_id);
} else {
  $stmt = $mysqli->prepare("
    SELECT
      tl.log_id,
      tl.created_at,
      tl.exercise_type,
      tl.reps_total,
      tl.reps_good,
      tl.fatigue_flag,
      tl.processing_ms,
      u.full_name AS trainee_name,
      EXISTS(
        SELECT 1 FROM expert_reviews er
        WHERE er.log_id = tl.log_id
          AND er.trainer_id = ?
        LIMIT 1
      ) AS is_reviewed
    FROM training_logs tl
    JOIN users u ON u.user_id = tl.user_id
    WHERE u.trainer_id = ?
    ORDER BY tl.created_at DESC
    LIMIT 12
  ");
  $stmt->bind_param("ii", $trainer_id, $trainer_id);
}

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
    <div class="row mb-3 align-items-center">
      <div class="col-md-7">
        <div class="lr-section-title mb-1">Coach Overview</div>
        <h1 class="lr-section-heading mb-1">Welcome, <?= h($full_name) ?> 👋</h1>
        <p class="lr-stat-subtext mb-0">
          <?= $selected_trainee ? 'Viewing: ' . h((string)$selected_trainee['full_name']) : 'Viewing: All assigned trainees' ?>
        </p>
      </div>

      <div class="col-md-5 mt-3 mt-md-0">
        <form method="get" class="d-flex gap-2 justify-content-md-end align-items-end">
          <div style="min-width: 260px;">
            <label class="form-label lr-stat-label mb-1">Select trainee</label>
            <select class="form-select" name="trainee_id" onchange="this.form.submit()">
              <option value="0">All trainees</option>
              <?php foreach ($trainees as $t): ?>
                <option value="<?= (int)$t['user_id'] ?>" <?= ((int)$t['user_id'] === $selected_trainee_id) ? 'selected' : '' ?>>
                  <?= h((string)$t['full_name']) ?>
                </option>
              <?php endforeach; ?>
            </select>
          </div>

          <?php if ($selected_trainee_id > 0): ?>
            <a class="btn btn-outline-light" href="<?= $BASE_URL ?>/coach/dashboard.php">Reset</a>
          <?php endif; ?>
        </form>
      </div>
    </div>

    <!-- Stats row -->
    <div class="row g-3 mb-4">
      <div class="col-md-3">
        <div class="lr-card h-100"><div class="lr-card-body">
          <div class="lr-stat-label">Total sessions</div>
          <div class="lr-stat-value mt-1"><?= (int)$stats['total_sessions'] ?></div>
          <div class="lr-stat-subtext mb-0"><?= $selected_trainee ? 'For selected trainee' : 'For all trainees' ?></div>
        </div></div>
      </div>

      <div class="col-md-3">
        <div class="lr-card h-100"><div class="lr-card-body">
          <div class="lr-stat-label"><?= $selected_trainee ? 'Trainees' : 'Active trainees' ?></div>
          <div class="lr-stat-value mt-1"><?= (int)$stats['total_users'] ?></div>
          <div class="lr-stat-subtext mb-0"><?= $selected_trainee ? 'Should be 1' : 'Users with logs' ?></div>
        </div></div>
      </div>

      <div class="col-md-3">
        <div class="lr-card h-100"><div class="lr-card-body">
          <div class="lr-stat-label">Average form</div>
          <div class="d-flex align-items-center gap-2 mt-1">
            <div class="lr-stat-value"><?= (int)$stats['avg_form'] ?>%</div>
            <span class="<?= h(formBadge((int)$stats['avg_form'])) ?>"><?= (int)$stats['avg_form'] ?>%</span>
          </div>
          <div class="lr-stat-subtext mb-0">reps_good / reps_total</div>
        </div></div>
      </div>

      <div class="col-md-3">
        <div class="lr-card h-100"><div class="lr-card-body">
          <div class="lr-stat-label">Pending reviews</div>
          <div class="lr-stat-value mt-1"><?= (int)$stats['pending_reviews'] ?></div>
          <div class="lr-stat-subtext mb-0">Not reviewed by you yet</div>
        </div></div>
      </div>
    </div>

    <!-- Secondary row -->
    <div class="row g-3 mb-4">
      <div class="col-md-6">
        <div class="lr-card h-100"><div class="lr-card-body d-flex justify-content-between align-items-center">
          <div>
            <div class="lr-stat-label">Fatigue-flagged sessions</div>
            <div class="lr-stat-subtext mb-0">fatigue_flag = 1</div>
          </div>
          <span class="lr-badge lr-badge-warning"><?= (int)$stats['fatigue_sessions'] ?></span>
        </div></div>
      </div>
      <div class="col-md-6">
        <div class="lr-card h-100"><div class="lr-card-body d-flex justify-content-between align-items-center">
          <div>
            <div class="lr-stat-label">Average processing latency</div>
            <div class="lr-stat-subtext mb-0">Objective 5</div>
          </div>
          <span class="lr-badge lr-badge-good">
            <?= $stats['avg_latency_ms'] === null ? '—' : h((string)$stats['avg_latency_ms'] . ' ms') ?>
          </span>
        </div></div>
      </div>
    </div>

    <!-- Per-trainee summary (only on All trainees view) -->
    <?php if ($selected_trainee_id === 0 && $trainee_summary): ?>
      <div class="lr-card mb-4">
        <div class="lr-card-header d-flex justify-content-between align-items-center">
          <div>
            <div class="lr-section-title mb-1">Trainees</div>
            <div class="lr-section-heading mb-0">Quick summary (per trainee)</div>
          </div>
          <div class="lr-stat-subtext mb-0"><?= count($trainee_summary) ?> trainee(s)</div>
        </div>

        <div class="lr-card-body p-0">
          <div class="table-responsive">
            <table class="table table-hover table-striped align-middle mb-0 table-lr-dark">
              <thead>
                <tr>
                  <th>Trainee</th>
                  <th class="text-end">Sessions</th>
                  <th class="text-end">Avg Form</th>
                  <th class="text-end">Fatigue</th>
                  <th class="text-end">Pending Reviews</th>
                  <th class="text-end"></th>
                </tr>
              </thead>
              <tbody>
                <?php foreach ($trainee_summary as $t): ?>
                  <?php
                    $sum_total = (int)($t['sum_total'] ?? 0);
                    $sum_good  = (int)($t['sum_good'] ?? 0);
                    $avg = ($sum_total > 0) ? (int)round(($sum_good / $sum_total) * 100) : 0;
                  ?>
                  <tr>
                    <td class="fw-semibold"><?= h((string)$t['full_name']) ?></td>
                    <td class="text-end"><?= (int)($t['sessions'] ?? 0) ?></td>
                    <td class="text-end"><span class="<?= h(formBadge($avg)) ?>"><?= (int)$avg ?>%</span></td>
                    <td class="text-end"><span class="lr-badge lr-badge-warning"><?= (int)($t['fatigue_sessions'] ?? 0) ?></span></td>
                    <td class="text-end">
                      <?php $p = (int)($t['pending_reviews'] ?? 0); ?>
                      <span class="<?= $p > 0 ? 'lr-badge lr-badge-warning' : 'lr-badge lr-badge-good' ?>"><?= $p ?></span>
                    </td>
                    <td class="text-end">
                      <a class="btn btn-sm btn-outline-light"
                         href="<?= $BASE_URL ?>/coach/dashboard.php?trainee_id=<?= (int)$t['user_id'] ?>">
                        View
                      </a>
                    </td>
                  </tr>
                <?php endforeach; ?>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    <?php endif; ?>

    <!-- Recent sessions -->
    <div class="lr-card">
      <div class="lr-card-header d-flex justify-content-between align-items-center">
        <div>
          <div class="lr-section-title mb-1">Latest Activity</div>
          <div class="lr-section-heading mb-0">
            <?= $selected_trainee ? 'Recent sessions (selected trainee)' : 'Recent sessions (all trainees)' ?>
          </div>
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
                <th>Form</th>
                <th>Fatigue</th>
                <th>Review</th>
                <th class="text-end">Latency</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <?php if (!$recent): ?>
                <tr><td colspan="8" class="text-center py-4 lr-stat-subtext">No sessions yet.</td></tr>
              <?php else: ?>
                <?php foreach ($recent as $s):
                  $pct = formPct((int)$s['reps_good'], (int)$s['reps_total']);
                  $reviewed = ((int)$s['is_reviewed'] === 1);
                ?>
                  <tr>
                    <td><?= h(date("M d, Y • g:i A", strtotime((string)$s['created_at']))) ?></td>
                    <td><?= h((string)$s['trainee_name']) ?></td>
                    <td><span class="lr-chip-exercise"><?= h(formatExercise((string)$s['exercise_type'])) ?></span></td>
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
                    <td class="text-end"><?= $s['processing_ms'] === null ? '—' : h((string)$s['processing_ms'] . ' ms') ?></td>
                    <td class="text-end">
                      <a class="btn btn-sm btn-outline-light"
                         href="<?= $BASE_URL ?>/coach/review-session.php?log_id=<?= (int)$s['log_id'] ?>">
                        Open
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
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>
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
if (!function_exists('h')) {
  function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
}

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
function reviewedBadge(bool $reviewed): string {
  return $reviewed ? 'lr-badge lr-badge-good' : 'lr-badge lr-badge-warning';
}

/* =========================================================
   0) Trainee searchable selector (max 5 suggestions)
   ========================================================= */

// inputs
$trainee_q = trim((string)($_GET['trainee_q'] ?? ''));
$selected_trainee_id = isset($_GET['trainee_id']) ? (int)$_GET['trainee_id'] : 0;

// suggestions: top 5 from what they typed (name/email/id)
$trainee_suggestions = [];
if ($trainee_q !== '') {
  $like = '%' . $trainee_q . '%';
  $stmt = $mysqli->prepare("
    SELECT user_id, full_name, email
    FROM users
    WHERE role='user'
      AND trainer_id=?
      AND (full_name LIKE ? OR email LIKE ? OR CAST(user_id AS CHAR) = ?)
    ORDER BY full_name ASC
    LIMIT 5
  ");
  $stmt->bind_param("isss", $trainer_id, $like, $like, $trainee_q);
  $stmt->execute();
  $res = $stmt->get_result();
  while ($r = $res->fetch_assoc()) $trainee_suggestions[] = $r;
  $stmt->close();
} else {
  // default suggestion list (top 5 alphabetically)
  $stmt = $mysqli->prepare("
    SELECT user_id, full_name, email
    FROM users
    WHERE role='user' AND trainer_id=?
    ORDER BY full_name ASC
    LIMIT 5
  ");
  $stmt->bind_param("i", $trainer_id);
  $stmt->execute();
  $res = $stmt->get_result();
  while ($r = $res->fetch_assoc()) $trainee_suggestions[] = $r;
  $stmt->close();
}

// validate selected trainee belongs to this coach (don’t trust GET)
$selected_trainee = null;
if ($selected_trainee_id > 0) {
  $stmt = $mysqli->prepare("
    SELECT user_id, full_name, email
    FROM users
    WHERE role='user' AND trainer_id=? AND user_id=?
    LIMIT 1
  ");
  $stmt->bind_param("ii", $trainer_id, $selected_trainee_id);
  $stmt->execute();
  $selected_trainee = $stmt->get_result()->fetch_assoc() ?: null;
  $stmt->close();

  if (!$selected_trainee) {
    $selected_trainee_id = 0;
  } else {
    if ($trainee_q === '') $trainee_q = (string)$selected_trainee['full_name'];
  }
}

/* =========================================================
   1) Overview stats (All trainees OR Selected trainee)
   ========================================================= */
$stats = [
  'total_sessions' => 0,
  'total_users' => 0,
  'avg_form' => 0,
  'fatigue_sessions' => 0, // kept for dashboard KPI display
  'avg_latency_ms' => null,
  'pending_reviews' => 0,
];

if ($selected_trainee_id > 0) {
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

/* =========================================================
   3) Per-trainee summary list (only when viewing ALL)
   ========================================================= */
$trainee_summary = [];
if ($selected_trainee_id === 0) {
  $stmt = $mysqli->prepare("
    SELECT
      u.user_id,
      u.full_name,
      COUNT(tl.log_id) AS sessions,
      SUM(tl.reps_good) AS sum_good,
      SUM(tl.reps_total) AS sum_total,
      SUM(CASE WHEN tl.fatigue_flag = 1 THEN 1 ELSE 0 END) AS fatigue_sessions,
      SUM(CASE WHEN er.review_id IS NULL AND tl.log_id IS NOT NULL THEN 1 ELSE 0 END) AS pending_reviews
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

/* =========================================================
   4) Recent sessions: FILTERS + PAGING (NO fatigue filter)
   ========================================================= */
$fx_exercise = trim((string)($_GET['exercise'] ?? ''));
$fx_reviewed = trim((string)($_GET['reviewed'] ?? ''));  // '', '0', '1'
$fx_from     = trim((string)($_GET['from'] ?? ''));      // YYYY-MM-DD
$fx_to       = trim((string)($_GET['to'] ?? ''));

$s_page = (int)($_GET['s_page'] ?? 1);
$s_per_page = (int)($_GET['s_per_page'] ?? 10);
if ($s_page < 1) $s_page = 1;

$allowedSPP = [10, 25, 50];
if (!in_array($s_per_page, $allowedSPP, true)) $s_per_page = 10;

$allowedExercises = ['bicep_curl','shoulder_press','lateral_raise'];
if (!in_array($fx_exercise, $allowedExercises, true)) $fx_exercise = '';

$where = [];
$types = "";
$params = [];

// always constrain to this trainer
$where[] = "u.trainer_id = ?";
$types .= "i";
$params[] = $trainer_id;

if ($selected_trainee_id > 0) {
  $where[] = "tl.user_id = ?";
  $types .= "i";
  $params[] = $selected_trainee_id;
}

if ($fx_exercise !== '') {
  $where[] = "tl.exercise_type = ?";
  $types .= "s";
  $params[] = $fx_exercise;
}

if ($fx_from !== '') {
  $where[] = "tl.created_at >= ?";
  $types .= "s";
  $params[] = $fx_from . " 00:00:00";
}
if ($fx_to !== '') {
  $where[] = "tl.created_at <= ?";
  $types .= "s";
  $params[] = $fx_to . " 23:59:59";
}

// reviewed EXISTS (no placeholders!)
$reviewExistsSql = "
  EXISTS(
    SELECT 1 FROM expert_reviews er
    WHERE er.log_id = tl.log_id
      AND er.trainer_id = " . (int)$trainer_id . "
    LIMIT 1
  )
";

if ($fx_reviewed === '1') {
  $where[] = $reviewExistsSql;
} elseif ($fx_reviewed === '0') {
  $where[] = "NOT " . $reviewExistsSql;
}

$whereSql = $where ? ("WHERE " . implode(" AND ", $where)) : "";

// count sessions
$countSql = "
  SELECT COUNT(*) AS cnt
  FROM training_logs tl
  JOIN users u ON u.user_id = tl.user_id
  $whereSql
";
$stmt = $mysqli->prepare($countSql);
if ($types !== "") $stmt->bind_param($types, ...$params);
$stmt->execute();
$total_sessions_rows = (int)($stmt->get_result()->fetch_assoc()['cnt'] ?? 0);
$stmt->close();

$s_total_pages = max(1, (int)ceil($total_sessions_rows / $s_per_page));
if ($s_page > $s_total_pages) $s_page = $s_total_pages;
$s_offset = ($s_page - 1) * $s_per_page;

// fetch page
$recent = [];
$dataSql = "
  SELECT
    tl.log_id,
    tl.created_at,
    tl.exercise_type,
    tl.reps_total,
    tl.reps_good,
    tl.processing_ms,
    u.full_name AS trainee_name,
    $reviewExistsSql AS is_reviewed
  FROM training_logs tl
  JOIN users u ON u.user_id = tl.user_id
  $whereSql
  ORDER BY tl.created_at DESC
  LIMIT ? OFFSET ?
";

$types2 = $types . "ii";
$params2 = $params;
$params2[] = $s_per_page;
$params2[] = $s_offset;

$stmt = $mysqli->prepare($dataSql);
$stmt->bind_param($types2, ...$params2);
$stmt->execute();
$res = $stmt->get_result();
while ($r = $res->fetch_assoc()) $recent[] = $r;
$stmt->close();

/* ---------- small query builder for pagination links ---------- */
function build_query(array $overrides = []): string {
  $q = $_GET;
  foreach ($overrides as $k => $v) {
    if ($v === null) unset($q[$k]);
    else $q[$k] = $v;
  }
  return http_build_query($q);
}

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

      <!-- Searchable trainee selector -->
      <div class="col-md-5 mt-3 mt-md-0">
        <form method="get" class="d-flex gap-2 justify-content-md-end align-items-end">
          <div style="min-width: 240px;">
            <label class="form-label lr-stat-label mb-1">Search trainee</label>
            <input class="form-control" name="trainee_q" value="<?= h($trainee_q) ?>" placeholder="Type name/email or ID">
          </div>

          <div style="min-width: 260px;">
            <label class="form-label lr-stat-label mb-1">Results (max 5)</label>
            <select class="form-select" name="trainee_id" onchange="this.form.submit()">
              <option value="0">All trainees</option>
              <?php foreach ($trainee_suggestions as $t): ?>
                <option value="<?= (int)$t['user_id'] ?>" <?= ((int)$t['user_id'] === $selected_trainee_id) ? 'selected' : '' ?>>
                  <?= h((string)$t['full_name']) ?> (<?= h((string)$t['email']) ?>)
                </option>
              <?php endforeach; ?>
            </select>
          </div>

          <button class="btn btn-outline-light" type="submit">Search</button>

          <?php if ($selected_trainee_id > 0 || $trainee_q !== ''): ?>
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

    <!-- Secondary row (kept KPI; no filter) -->
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
                    $p = (int)($t['pending_reviews'] ?? 0);
                  ?>
                  <tr>
                    <td class="fw-semibold"><?= h((string)$t['full_name']) ?></td>
                    <td class="text-end"><?= (int)($t['sessions'] ?? 0) ?></td>
                    <td class="text-end"><span class="<?= h(formBadge($avg)) ?>"><?= (int)$avg ?>%</span></td>
                    <td class="text-end"><span class="lr-badge lr-badge-warning"><?= (int)($t['fatigue_sessions'] ?? 0) ?></span></td>
                    <td class="text-end">
                      <span class="<?= $p > 0 ? 'lr-badge lr-badge-warning' : 'lr-badge lr-badge-good' ?>"><?= $p ?></span>
                    </td>
                    <td class="text-end">
                      <a class="btn btn-sm btn-outline-light"
                         href="<?= $BASE_URL ?>/coach/dashboard.php?<?= h(build_query(['trainee_id'=>(int)$t['user_id'], 'trainee_q'=>(string)$t['full_name'], 's_page'=>1])) ?>">
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

    <!-- Recent sessions filters (NO fatigue filter) -->
    <div class="lr-card mb-3">
      <div class="lr-card-body">
        <form method="get" class="row g-2 align-items-end">
          <!-- preserve trainee selection -->
          <input type="hidden" name="trainee_id" value="<?= (int)$selected_trainee_id ?>">
          <input type="hidden" name="trainee_q" value="<?= h($trainee_q) ?>">

          <div class="col-md-3">
            <label class="form-label lr-stat-label">Exercise</label>
            <select class="form-select" name="exercise">
              <option value="">All</option>
              <option value="bicep_curl" <?= $fx_exercise==='bicep_curl'?'selected':'' ?>>Bicep Curl</option>
              <option value="shoulder_press" <?= $fx_exercise==='shoulder_press'?'selected':'' ?>>Shoulder Press</option>
              <option value="lateral_raise" <?= $fx_exercise==='lateral_raise'?'selected':'' ?>>Lateral Raise</option>
            </select>
          </div>

          <div class="col-md-2">
            <label class="form-label lr-stat-label">Reviewed</label>
            <select class="form-select" name="reviewed">
              <option value="">All</option>
              <option value="1" <?= $fx_reviewed==='1'?'selected':'' ?>>Reviewed</option>
              <option value="0" <?= $fx_reviewed==='0'?'selected':'' ?>>Pending</option>
            </select>
          </div>

          <div class="col-md-4 d-flex gap-2">
            <div style="flex:1;">
              <label class="form-label lr-stat-label">From</label>
              <input class="form-control" type="date" name="from" value="<?= h($fx_from) ?>">
            </div>
            <div style="flex:1;">
              <label class="form-label lr-stat-label">To</label>
              <input class="form-control" type="date" name="to" value="<?= h($fx_to) ?>">
            </div>
          </div>

          <div class="col-md-3">
            <label class="form-label lr-stat-label">Per page</label>
            <select class="form-select" name="s_per_page">
              <?php foreach ([10,25,50] as $n): ?>
                <option value="<?= $n ?>" <?= $s_per_page===$n?'selected':'' ?>><?= $n ?></option>
              <?php endforeach; ?>
            </select>
          </div>

          <input type="hidden" name="s_page" value="1">

          <div class="col-12 d-flex gap-2 justify-content-end mt-2">
            <button class="btn btn-primary" type="submit">Apply</button>
            <a class="btn btn-outline-light" href="<?= $BASE_URL ?>/coach/dashboard.php?<?= h(build_query([
              'exercise'=>null,'reviewed'=>null,'from'=>null,'to'=>null,'s_page'=>1,'s_per_page'=>10
            ])) ?>">Reset filters</a>
          </div>
        </form>
      </div>
    </div>

    <!-- Recent sessions table (paged) -->
    <div class="lr-card">
      <div class="lr-card-header d-flex justify-content-between align-items-center">
        <div>
          <div class="lr-section-title mb-1">Latest Activity</div>
          <div class="lr-section-heading mb-0">
            <?= $selected_trainee ? 'Sessions (selected trainee)' : 'Sessions (all trainees)' ?>
          </div>
        </div>
        <div class="lr-stat-subtext mb-0">
          Showing <?= ($total_sessions_rows === 0) ? 0 : ($s_offset + 1) ?>–<?= min($s_offset + $s_per_page, $total_sessions_rows) ?>
          of <?= (int)$total_sessions_rows ?>
        </div>
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
                <th>Review</th>
                <th class="text-end">Latency</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <?php if (!$recent): ?>
                <tr><td colspan="7" class="text-center py-4 lr-stat-subtext">No sessions found.</td></tr>
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

      <div class="d-flex justify-content-between align-items-center p-3 border-top">
        <div class="lr-stat-subtext mb-0">
          Page <?= (int)$s_page ?> of <?= (int)$s_total_pages ?>
        </div>

        <nav aria-label="Sessions pagination">
          <ul class="pagination pagination-sm mb-0">
            <?php
              $prevDisabled = ($s_page <= 1) ? ' disabled' : '';
              $nextDisabled = ($s_page >= $s_total_pages) ? ' disabled' : '';

              $prevUrl = $BASE_URL . "/coach/dashboard.php?" . build_query(['s_page' => max(1, $s_page - 1)]);
              $nextUrl = $BASE_URL . "/coach/dashboard.php?" . build_query(['s_page' => min($s_total_pages, $s_page + 1)]);
            ?>
            <li class="page-item<?= $prevDisabled ?>">
              <a class="page-link" href="<?= $prevDisabled ? '#' : h($prevUrl) ?>">Prev</a>
            </li>
            <li class="page-item<?= $nextDisabled ?>">
              <a class="page-link" href="<?= $nextDisabled ? '#' : h($nextUrl) ?>">Next</a>
            </li>
          </ul>
        </nav>
      </div>

    </div>

  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>
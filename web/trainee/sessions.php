<?php
// liftright/web/trainee/sessions.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['user']);
$page_title = "My Sessions";

$user_id = (int)$_SESSION['user_id'];

if (!function_exists('h')) {
  function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
}

/* ---------------------------
   Filters
----------------------------*/
$exercise  = trim((string)($_GET['exercise'] ?? ''));
$fatigue   = trim((string)($_GET['fatigue'] ?? ''));
$source    = trim((string)($_GET['source'] ?? ''));
$q         = trim((string)($_GET['q'] ?? ''));

$date_from = trim((string)($_GET['date_from'] ?? '')); // YYYY-MM-DD
$date_to   = trim((string)($_GET['date_to'] ?? ''));   // YYYY-MM-DD

$min_form  = trim((string)($_GET['min_form'] ?? ''));  // integer 0-100
$min_reps  = trim((string)($_GET['min_reps'] ?? ''));  // integer >=0

$sort      = trim((string)($_GET['sort'] ?? 'newest')); // newest/oldest/form_desc/form_asc/reps_desc/reps_asc/lat_desc/lat_asc

// Paging
$page     = (int)($_GET['page'] ?? 1);
$per_page = (int)($_GET['per_page'] ?? 5);
if ($page < 1) $page = 1;

$allowedPerPage = [5, 10, 25, 50, 100];
if (!in_array($per_page, $allowedPerPage, true)) $per_page = 25;

// Validate filters
$allowedExercises = ['bicep_curl','shoulder_press','lateral_raise'];
$exercise = in_array($exercise, $allowedExercises, true) ? $exercise : '';

$allowedFatigue = ['0','1'];
$fatigue = in_array($fatigue, $allowedFatigue, true) ? $fatigue : '';

$allowedSource = ['upload','webcam'];
$source = in_array($source, $allowedSource, true) ? $source : '';

// date validation (simple)
$validDate = function(string $d): bool {
  if ($d === '') return false;
  $t = strtotime($d);
  return $t !== false && preg_match('/^\d{4}-\d{2}-\d{2}$/', $d);
};
if (!$validDate($date_from)) $date_from = '';
if (!$validDate($date_to))   $date_to = '';

// numeric validation
if ($min_form !== '') {
  if (!ctype_digit($min_form)) $min_form = '';
  else {
    $mf = (int)$min_form;
    if ($mf < 0) $mf = 0;
    if ($mf > 100) $mf = 100;
    $min_form = (string)$mf;
  }
}
if ($min_reps !== '') {
  if (!ctype_digit($min_reps)) $min_reps = '';
  else {
    $mr = (int)$min_reps;
    if ($mr < 0) $mr = 0;
    $min_reps = (string)$mr;
  }
}

// sort whitelist
$allowedSort = ['newest','oldest','form_desc','form_asc','reps_desc','reps_asc','lat_desc','lat_asc'];
if (!in_array($sort, $allowedSort, true)) $sort = 'newest';

/* ---------------------------
   Helpers
----------------------------*/
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

/* ---------------------------
   Build WHERE + params once
----------------------------*/
$where = " WHERE user_id = ? ";
$types = "i";
$params = [$user_id];

if ($exercise !== '') {
  $where .= " AND exercise_type = ? ";
  $types .= "s";
  $params[] = $exercise;
}

if ($fatigue !== '') {
  $where .= " AND fatigue_flag = ? ";
  $types .= "i";
  $params[] = (int)$fatigue;
}

if ($source !== '') {
  $where .= " AND source_type = ? ";
  $types .= "s";
  $params[] = $source;
}

if ($q !== '') {
  $where .= " AND (exercise_type LIKE CONCAT('%', ?, '%') OR source_type LIKE CONCAT('%', ?, '%')) ";
  $types .= "ss";
  $params[] = $q;
  $params[] = $q;
}

if ($date_from !== '') {
  // inclusive start of day
  $where .= " AND created_at >= CONCAT(?, ' 00:00:00') ";
  $types .= "s";
  $params[] = $date_from;
}

if ($date_to !== '') {
  // inclusive end of day
  $where .= " AND created_at <= CONCAT(?, ' 23:59:59') ";
  $types .= "s";
  $params[] = $date_to;
}

if ($min_reps !== '') {
  $where .= " AND reps_total >= ? ";
  $types .= "i";
  $params[] = (int)$min_reps;
}

if ($min_form !== '') {
  // avoid division by zero; require reps_total > 0 when filtering by pct
  // pct = ROUND(reps_good/reps_total*100)
  $where .= " AND reps_total > 0 AND (reps_good / reps_total) * 100 >= ? ";
  $types .= "i";
  $params[] = (int)$min_form;
}

/* ---------------------------
   Sorting
----------------------------*/
$orderBy = " ORDER BY created_at DESC ";
switch ($sort) {
  case 'oldest':
    $orderBy = " ORDER BY created_at ASC ";
    break;
  case 'form_desc':
    $orderBy = " ORDER BY (CASE WHEN reps_total > 0 THEN reps_good / reps_total ELSE 0 END) DESC, created_at DESC ";
    break;
  case 'form_asc':
    $orderBy = " ORDER BY (CASE WHEN reps_total > 0 THEN reps_good / reps_total ELSE 0 END) ASC, created_at DESC ";
    break;
  case 'reps_desc':
    $orderBy = " ORDER BY reps_total DESC, created_at DESC ";
    break;
  case 'reps_asc':
    $orderBy = " ORDER BY reps_total ASC, created_at DESC ";
    break;
  case 'lat_desc':
    $orderBy = " ORDER BY (CASE WHEN processing_ms IS NULL THEN -1 ELSE processing_ms END) DESC, created_at DESC ";
    break;
  case 'lat_asc':
    $orderBy = " ORDER BY (CASE WHEN processing_ms IS NULL THEN 999999999 ELSE processing_ms END) ASC, created_at DESC ";
    break;
  default:
    $orderBy = " ORDER BY created_at DESC ";
}

/* ---------------------------
   Total count for paging
----------------------------*/
$countSql = "SELECT COUNT(*) AS cnt FROM training_logs " . $where;
$stmt = $mysqli->prepare($countSql);
$stmt->bind_param($types, ...$params);
$stmt->execute();
$total_rows = (int)($stmt->get_result()->fetch_assoc()['cnt'] ?? 0);
$stmt->close();

$total_pages = max(1, (int)ceil($total_rows / $per_page));
if ($page > $total_pages) $page = $total_pages;

$offset = ($page - 1) * $per_page;

/* ---------------------------
   Fetch current page rows
----------------------------*/
$dataSql = "
  SELECT log_id, exercise_type, source_type,
         reps_total, reps_good, reps_bad, form_error_count, fatigue_flag,
         processing_ms, created_at
  FROM training_logs
  $where
  $orderBy
  LIMIT ? OFFSET ?
";

$dataTypes = $types . "ii";
$dataParams = $params;
$dataParams[] = $per_page;
$dataParams[] = $offset;

$stmt = $mysqli->prepare($dataSql);
$stmt->bind_param($dataTypes, ...$dataParams);
$stmt->execute();
$res = $stmt->get_result();

$sessions = [];
while ($row = $res->fetch_assoc()) $sessions[] = $row;
$stmt->close();

/* ---------------------------
   Paging URL builder
----------------------------*/
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
    <div class="row mb-4 align-items-center">
      <div class="col-md-8">
        <div class="lr-section-title mb-1">History</div>
        <h1 class="lr-section-heading mb-1">My Sessions</h1>
        <p class="lr-stat-subtext mb-0">Browse your recorded sessions and open a detailed rep breakdown.</p>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0">
        <a class="btn btn-primary px-3" href="<?= $BASE_URL ?>/trainee/start-session.php">
          Start New Session
        </a>
      </div>
    </div>

    <!-- Filters (same look, just more options) -->
    <div class="lr-card mb-4">
      <div class="lr-card-body">
        <form class="row g-2 align-items-end" method="get">

          <div class="col-md-3">
            <label class="form-label lr-stat-label">Exercise</label>
            <select class="form-select" name="exercise">
              <option value="">All</option>
              <option value="bicep_curl" <?= $exercise==='bicep_curl'?'selected':'' ?>>Bicep Curl</option>
              <option value="shoulder_press" <?= $exercise==='shoulder_press'?'selected':'' ?>>Shoulder Press</option>
              <option value="lateral_raise" <?= $exercise==='lateral_raise'?'selected':'' ?>>Lateral Raise</option>
            </select>
          </div>

          <div class="col-md-2">
            <label class="form-label lr-stat-label">Fatigue flag</label>
            <select class="form-select" name="fatigue">
              <option value="">All</option>
              <option value="0" <?= $fatigue==='0'?'selected':'' ?>>Normal</option>
              <option value="1" <?= $fatigue==='1'?'selected':'' ?>>Warning</option>
            </select>
          </div>

          <div class="col-md-2">
            <label class="form-label lr-stat-label">Source</label>
            <select class="form-select" name="source">
              <option value="">All</option>
              <option value="upload" <?= $source==='upload'?'selected':'' ?>>Upload</option>
              <option value="webcam" <?= $source==='webcam'?'selected':'' ?>>Webcam</option>
            </select>
          </div>

          <div class="col-md-2">
            <label class="form-label lr-stat-label">Date from</label>
            <input type="date" class="form-control" name="date_from" value="<?= h($date_from) ?>">
          </div>

          <div class="col-md-2">
            <label class="form-label lr-stat-label">Date to</label>
            <input type="date" class="form-control" name="date_to" value="<?= h($date_to) ?>">
          </div>

          <div class="col-md-3">
            <label class="form-label lr-stat-label">Search</label>
            <input class="form-control" name="q" placeholder="exercise / source..." value="<?= h($q) ?>">
          </div>

          <div class="col-md-2">
            <label class="form-label lr-stat-label">Min form %</label>
            <input class="form-control" name="min_form" inputmode="numeric" placeholder="e.g. 80" value="<?= h($min_form) ?>">
          </div>

          <div class="col-md-2">
            <label class="form-label lr-stat-label">Min reps</label>
            <input class="form-control" name="min_reps" inputmode="numeric" placeholder="e.g. 10" value="<?= h($min_reps) ?>">
          </div>

          <div class="col-md-2">
            <label class="form-label lr-stat-label">Sort</label>
            <select class="form-select" name="sort">
              <option value="newest" <?= $sort==='newest'?'selected':'' ?>>Newest</option>
              <option value="oldest" <?= $sort==='oldest'?'selected':'' ?>>Oldest</option>
              <option value="form_desc" <?= $sort==='form_desc'?'selected':'' ?>>Form (high → low)</option>
              <option value="form_asc" <?= $sort==='form_asc'?'selected':'' ?>>Form (low → high)</option>
              <option value="reps_desc" <?= $sort==='reps_desc'?'selected':'' ?>>Reps (high → low)</option>
              <option value="reps_asc" <?= $sort==='reps_asc'?'selected':'' ?>>Reps (low → high)</option>
              <option value="lat_desc" <?= $sort==='lat_desc'?'selected':'' ?>>Latency (high → low)</option>
              <option value="lat_asc" <?= $sort==='lat_asc'?'selected':'' ?>>Latency (low → high)</option>
            </select>
          </div>

          <div class="col-md-2">
            <label class="form-label lr-stat-label">Per page</label>
            <select class="form-select" name="per_page">
              <?php foreach ([5, 10,25,50,100] as $pp): ?>
                <option value="<?= $pp ?>" <?= $per_page===$pp?'selected':'' ?>><?= $pp ?></option>
              <?php endforeach; ?>
            </select>
          </div>

          <div class="col-md-2 d-grid">
            <button class="btn btn-outline-light">Apply</button>
          </div>

          <div class="col-md-2 d-grid">
            <a class="btn btn-outline-light" href="<?= $BASE_URL ?>/trainee/sessions.php">Reset</a>
          </div>

          <!-- keep page when applying filters? no: always reset to page 1 on Apply -->
          <input type="hidden" name="page" value="1">

        </form>
      </div>
    </div>

    <!-- Table -->
    <div class="lr-card">
      <div class="lr-card-header d-flex justify-content-between align-items-center">
        <div>
          <div class="lr-section-title mb-1">Sessions</div>
          <div class="lr-section-heading mb-0">Latest logs</div>
        </div>
        <div class="lr-stat-subtext mb-0">
          <?= (int)$total_rows ?> total • page <?= (int)$page ?>/<?= (int)$total_pages ?>
        </div>
      </div>

      <div class="lr-card-body p-0">
        <div class="table-responsive">
          <table class="table table-hover table-striped align-middle mb-0 table-lr-dark">
            <thead>
              <tr>
                <th>Date</th>
                <th>Exercise</th>
                <th>Source</th>
                <th>Reps</th>
                <th>Form</th>
                <th>Fatigue</th>
                <th class="text-end">Latency</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
            <?php if (count($sessions) === 0): ?>
              <tr>
                <td colspan="8" class="text-center py-4 lr-stat-subtext">No sessions found.</td>
              </tr>
            <?php else: ?>
              <?php foreach ($sessions as $s):
                $total = (int)$s['reps_total'];
                $good  = (int)$s['reps_good'];
                $pct   = formPct($good, $total);
              ?>
                <tr>
                  <td><?= h(date("M d, Y • g:i A", strtotime((string)$s['created_at']))) ?></td>
                  <td><span class="lr-chip-exercise"><?= h(formatExercise((string)$s['exercise_type'])) ?></span></td>
                  <td class="text-capitalize"><?= h((string)$s['source_type']) ?></td>
                  <td><?= (int)$s['reps_good'] ?> good / <?= (int)$s['reps_total'] ?> total</td>
                  <td><span class="<?= h(formBadge($pct)) ?>"><?= (int)$pct ?>%</span></td>
                  <td>
                    <span class="<?= h(fatigueBadge((int)$s['fatigue_flag'])) ?>">
                      <?= ((int)$s['fatigue_flag'] === 1) ? 'Warning' : 'Normal' ?>
                    </span>
                  </td>
                  <td class="text-end">
                    <?= $s['processing_ms'] === null ? '—' : h((string)$s['processing_ms'] . ' ms') ?>
                  </td>
                  <td class="text-end">
                    <a class="btn btn-sm btn-outline-light"
                       href="<?= $BASE_URL ?>/trainee/session-view.php?log_id=<?= (int)$s['log_id'] ?>">
                      View
                    </a>
                  </td>
                </tr>
              <?php endforeach; ?>
            <?php endif; ?>
            </tbody>
          </table>
        </div>

        <!-- Paging controls -->
        <div class="d-flex justify-content-between align-items-center p-3">
          <div class="lr-stat-subtext mb-0">
            Showing <?= ($total_rows === 0) ? 0 : ($offset + 1) ?>–<?= min($offset + $per_page, $total_rows) ?> of <?= $total_rows ?>
          </div>

          <nav aria-label="Sessions pagination">
            <ul class="pagination pagination-sm mb-0">

              <?php
                $prevDisabled = ($page <= 1) ? ' disabled' : '';
                $nextDisabled = ($page >= $total_pages) ? ' disabled' : '';

                $prevUrl = $BASE_URL . "/trainee/sessions.php?" . build_query(['page' => max(1, $page - 1)]);
                $nextUrl = $BASE_URL . "/trainee/sessions.php?" . build_query(['page' => min($total_pages, $page + 1)]);

                // page window
                $window = 2;
                $start = max(1, $page - $window);
                $end = min($total_pages, $page + $window);
              ?>

              <li class="page-item<?= $prevDisabled ?>">
                <a class="page-link" href="<?= $prevDisabled ? '#' : h($prevUrl) ?>" tabindex="-1">Prev</a>
              </li>

              <?php if ($start > 1): ?>
                <li class="page-item">
                  <a class="page-link" href="<?= h($BASE_URL . "/trainee/sessions.php?" . build_query(['page' => 1])) ?>">1</a>
                </li>
                <?php if ($start > 2): ?>
                  <li class="page-item disabled"><span class="page-link">…</span></li>
                <?php endif; ?>
              <?php endif; ?>

              <?php for ($p = $start; $p <= $end; $p++): ?>
                <li class="page-item<?= ($p === $page) ? ' active' : '' ?>">
                  <a class="page-link" href="<?= h($BASE_URL . "/trainee/sessions.php?" . build_query(['page' => $p])) ?>">
                    <?= $p ?>
                  </a>
                </li>
              <?php endfor; ?>

              <?php if ($end < $total_pages): ?>
                <?php if ($end < $total_pages - 1): ?>
                  <li class="page-item disabled"><span class="page-link">…</span></li>
                <?php endif; ?>
                <li class="page-item">
                  <a class="page-link" href="<?= h($BASE_URL . "/trainee/sessions.php?" . build_query(['page' => $total_pages])) ?>">
                    <?= $total_pages ?>
                  </a>
                </li>
              <?php endif; ?>

              <li class="page-item<?= $nextDisabled ?>">
                <a class="page-link" href="<?= $nextDisabled ? '#' : h($nextUrl) ?>">Next</a>
              </li>

            </ul>
          </nav>
        </div>

      </div>
    </div>

  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>
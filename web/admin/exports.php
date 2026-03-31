<?php
// liftright/web/admin/exports.php (PRIVACY-FIRST + POLISHED)

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['admin']);
$page_title = "Exports";

if (!function_exists('h')) {
  function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
}

/* ---------------- CSV helpers ---------------- */

function csv_sanitize_excel(string $s): string {
  // Prevent CSV/Excel formula injection
  // If a field begins with =, +, -, @ Excel may treat it as a formula.
  if ($s === '') return $s;
  $first = $s[0];
  if ($first === '=' || $first === '+' || $first === '-' || $first === '@') {
    return "'" . $s;
  }
  return $s;
}

function csv_row(array $row): string {
  $out = [];
  foreach ($row as $v) {
    $s = (string)$v;
    $s = str_replace(["\r","\n"], [' ',' '], $s); // single-line CSV rows
    $s = csv_sanitize_excel($s);
    $s = str_replace('"', '""', $s);
    $out[] = '"' . $s . '"';
  }
  return implode(",", $out) . "\r\n";
}

/* ---------------- Filters ---------------- */

$download = (string)($_GET['download'] ?? '');

$from = trim((string)($_GET['from'] ?? ''));
$to   = trim((string)($_GET['to'] ?? ''));
$exercise = trim((string)($_GET['exercise'] ?? '')); // bicep_curl/shoulder_press/lateral_raise
$fatigue  = trim((string)($_GET['fatigue'] ?? ''));  // 1/0
$reviewed = trim((string)($_GET['reviewed'] ?? '')); // 1/0 (sessions only)

$from_ok = preg_match('/^\d{4}-\d{2}-\d{2}$/', $from);
$to_ok   = preg_match('/^\d{4}-\d{2}-\d{2}$/', $to);
$exercise_ok = in_array($exercise, ['bicep_curl','shoulder_press','lateral_raise'], true);
$fatigue_ok = ($fatigue === '1' || $fatigue === '0');
$reviewed_ok = ($reviewed === '1' || $reviewed === '0');

// Filters summary (for UI)
$active_filters = [];
if ($from_ok) $active_filters[] = "From: " . $from;
if ($to_ok) $active_filters[] = "To: " . $to;
if ($exercise_ok) $active_filters[] = "Exercise: " . ucwords(str_replace('_',' ', $exercise));
if ($fatigue_ok) $active_filters[] = "Fatigue: " . (($fatigue === '1') ? "Yes" : "No");
if ($reviewed_ok) $active_filters[] = "Reviewed: " . (($reviewed === '1') ? "Yes" : "No");

/* ---------------- Download handlers ---------------- */

if ($download !== '') {
  header('Content-Type: text/csv; charset=utf-8');
  header('Pragma: no-cache');
  header('Expires: 0');

  // Base filename helper (reflect filters)
  $suffix_parts = [];
  if ($from_ok) $suffix_parts[] = "from_" . $from;
  if ($to_ok) $suffix_parts[] = "to_" . $to;
  if ($exercise_ok) $suffix_parts[] = $exercise;
  if ($fatigue_ok) $suffix_parts[] = "fatigue_" . $fatigue;
  if ($reviewed_ok) $suffix_parts[] = "reviewed_" . $reviewed;
  $suffix = $suffix_parts ? ("_" . implode("_", $suffix_parts)) : "";
  $suffix = preg_replace('/[^A-Za-z0-9_\-]/', '_', $suffix);

  // --- SESSIONS EXPORT (privacy-first: no name/email) ---
  if ($download === 'sessions') {
    header('Content-Disposition: attachment; filename="liftright_sessions' . $suffix . '.csv"');

    echo csv_row([
      'log_id','user_id','exercise_type','source_type',
      'reps_total','reps_good','reps_bad',
      'fatigue_flag','processing_ms','created_at','reviewed'
    ]);

    $where = "1=1";
    $types = "";
    $params = [];

    if ($from_ok) { $where .= " AND DATE(l.created_at) >= ?"; $types.="s"; $params[]=$from; }
    if ($to_ok)   { $where .= " AND DATE(l.created_at) <= ?"; $types.="s"; $params[]=$to; }
    if ($exercise_ok) { $where .= " AND l.exercise_type = ?"; $types.="s"; $params[]=$exercise; }
    if ($fatigue_ok)  { $where .= " AND l.fatigue_flag = ?"; $types.="i"; $params[]=(int)$fatigue; }

    // reviewed filter uses LEFT JOIN
    if ($reviewed_ok) {
      $where .= ($reviewed === '1') ? " AND er.review_id IS NOT NULL" : " AND er.review_id IS NULL";
    }

    $sql = "
      SELECT
        l.log_id, l.user_id, l.exercise_type, l.source_type,
        l.reps_total, l.reps_good, l.reps_bad,
        l.fatigue_flag, l.processing_ms, l.created_at,
        CASE WHEN er.review_id IS NULL THEN 0 ELSE 1 END AS reviewed
      FROM training_logs l
      LEFT JOIN expert_reviews er ON er.log_id = l.log_id
      WHERE $where
      ORDER BY l.created_at DESC
      LIMIT 5000
    ";

    $stmt = $mysqli->prepare($sql);
    if ($types !== "") $stmt->bind_param($types, ...$params);
    $stmt->execute();
    $res = $stmt->get_result();
    while ($r = $res->fetch_assoc()) echo csv_row($r);
    $stmt->close();
    exit;
  }

  // --- REP METRICS EXPORT ---
  if ($download === 'rep_metrics') {
    header('Content-Disposition: attachment; filename="liftright_rep_metrics' . $suffix . '.csv"');

    echo csv_row([
      'rep_id','log_id','rep_index','duration_ms',
      'rom_score','trunk_sway','confidence_avg','form_label','anomaly_score',
      'created_at'
    ]);

    $where = "1=1";
    $types = "";
    $params = [];

    if ($from_ok) { $where .= " AND DATE(created_at) >= ?"; $types.="s"; $params[]=$from; }
    if ($to_ok)   { $where .= " AND DATE(created_at) <= ?"; $types.="s"; $params[]=$to; }

    $stmt = $mysqli->prepare("
      SELECT rep_id, log_id, rep_index, duration_ms, rom_score, trunk_sway, confidence_avg, form_label, anomaly_score, created_at
      FROM rep_metrics
      WHERE $where
      ORDER BY created_at DESC
      LIMIT 20000
    ");
    if ($types !== "") $stmt->bind_param($types, ...$params);
    $stmt->execute();
    $res = $stmt->get_result();
    while ($r = $res->fetch_assoc()) echo csv_row($r);
    $stmt->close();
    exit;
  }

  // --- SUS EXPORT ---
  if ($download === 'sus') {
    header('Content-Disposition: attachment; filename="liftright_sus_responses' . $suffix . '.csv"');

    echo csv_row([
      'sus_id','user_id','q1','q2','q3','q4','q5','q6','q7','q8','q9','q10',
      'sus_score','created_at'
    ]);

    $where = "1=1";
    $types = "";
    $params = [];

    if ($from_ok) { $where .= " AND DATE(created_at) >= ?"; $types.="s"; $params[]=$from; }
    if ($to_ok)   { $where .= " AND DATE(created_at) <= ?"; $types.="s"; $params[]=$to; }

    $stmt = $mysqli->prepare("
      SELECT sus_id, user_id, q1,q2,q3,q4,q5,q6,q7,q8,q9,q10, sus_score, created_at
      FROM sus_responses
      WHERE $where
      ORDER BY created_at DESC
      LIMIT 20000
    ");
    if ($types !== "") $stmt->bind_param($types, ...$params);
    $stmt->execute();
    $res = $stmt->get_result();
    while ($r = $res->fetch_assoc()) echo csv_row($r);
    $stmt->close();
    exit;
  }

  // --- EXPERT REVIEWS EXPORT (privacy-first: no trainer_name) ---
  if ($download === 'expert_reviews') {
    header('Content-Disposition: attachment; filename="liftright_expert_reviews' . $suffix . '.csv"');

    echo csv_row([
      'review_id','log_id','trainer_id',
      'rating','notes','marked_good_reps','marked_bad_reps',
      'created_at','exercise_type'
    ]);

    $where = "1=1";
    $types = "";
    $params = [];

    if ($from_ok) { $where .= " AND DATE(er.created_at) >= ?"; $types.="s"; $params[]=$from; }
    if ($to_ok)   { $where .= " AND DATE(er.created_at) <= ?"; $types.="s"; $params[]=$to; }
    if ($exercise_ok) { $where .= " AND l.exercise_type = ?"; $types.="s"; $params[]=$exercise; }

    $stmt = $mysqli->prepare("
      SELECT
        er.review_id, er.log_id, er.trainer_id,
        er.rating, er.notes, er.marked_good_reps, er.marked_bad_reps,
        er.created_at, l.exercise_type
      FROM expert_reviews er
      JOIN training_logs l ON l.log_id = er.log_id
      WHERE $where
      ORDER BY er.created_at DESC
      LIMIT 20000
    ");
    if ($types !== "") $stmt->bind_param($types, ...$params);
    $stmt->execute();
    $res = $stmt->get_result();
    while ($r = $res->fetch_assoc()) echo csv_row($r);
    $stmt->close();
    exit;
  }

  http_response_code(400);
  echo "Invalid export.";
  exit;
}

/* ---------------- Counts preview (for nicer admin UX) ---------------- */

$counts = [
  'sessions' => 0,
  'rep_metrics' => 0,
  'sus' => 0,
  'expert_reviews' => 0,
];

// sessions count (matches sessions export logic)
$where = "1=1";
$types = "";
$params = [];
if ($from_ok) { $where .= " AND DATE(l.created_at) >= ?"; $types.="s"; $params[]=$from; }
if ($to_ok)   { $where .= " AND DATE(l.created_at) <= ?"; $types.="s"; $params[]=$to; }
if ($exercise_ok) { $where .= " AND l.exercise_type = ?"; $types.="s"; $params[]=$exercise; }
if ($fatigue_ok)  { $where .= " AND l.fatigue_flag = ?"; $types.="i"; $params[]=(int)$fatigue; }
if ($reviewed_ok) {
  $where .= ($reviewed === '1') ? " AND er.review_id IS NOT NULL" : " AND er.review_id IS NULL";
}

$stmt = $mysqli->prepare("
  SELECT COUNT(*) AS c
  FROM training_logs l
  LEFT JOIN expert_reviews er ON er.log_id = l.log_id
  WHERE $where
");
if ($types !== "") $stmt->bind_param($types, ...$params);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();
$counts['sessions'] = (int)($row['c'] ?? 0);

// rep_metrics count (date filters only)
$where = "1=1";
$types = "";
$params = [];
if ($from_ok) { $where .= " AND DATE(created_at) >= ?"; $types.="s"; $params[]=$from; }
if ($to_ok)   { $where .= " AND DATE(created_at) <= ?"; $types.="s"; $params[]=$to; }

$stmt = $mysqli->prepare("SELECT COUNT(*) AS c FROM rep_metrics WHERE $where");
if ($types !== "") $stmt->bind_param($types, ...$params);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();
$counts['rep_metrics'] = (int)($row['c'] ?? 0);

// sus count (date filters only)
$where = "1=1";
$types = "";
$params = [];
if ($from_ok) { $where .= " AND DATE(created_at) >= ?"; $types.="s"; $params[]=$from; }
if ($to_ok)   { $where .= " AND DATE(created_at) <= ?"; $types.="s"; $params[]=$to; }

$stmt = $mysqli->prepare("SELECT COUNT(*) AS c FROM sus_responses WHERE $where");
if ($types !== "") $stmt->bind_param($types, ...$params);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();
$counts['sus'] = (int)($row['c'] ?? 0);

// expert_reviews count (matches expert export logic)
$where = "1=1";
$types = "";
$params = [];
if ($from_ok) { $where .= " AND DATE(er.created_at) >= ?"; $types.="s"; $params[]=$from; }
if ($to_ok)   { $where .= " AND DATE(er.created_at) <= ?"; $types.="s"; $params[]=$to; }
if ($exercise_ok) { $where .= " AND l.exercise_type = ?"; $types.="s"; $params[]=$exercise; }

$stmt = $mysqli->prepare("
  SELECT COUNT(*) AS c
  FROM expert_reviews er
  JOIN training_logs l ON l.log_id = er.log_id
  WHERE $where
");
if ($types !== "") $stmt->bind_param($types, ...$params);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();
$counts['expert_reviews'] = (int)($row['c'] ?? 0);

/* ---------------- Download links (carry filters) ---------------- */

$qs = http_build_query([
  'from' => $from,
  'to' => $to,
  'exercise' => $exercise,
  'fatigue' => $fatigue,
  'reviewed' => $reviewed,
]);
$qs = $qs ? '&' . $qs : '';

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="lr-page-wrapper">
  <div class="container lr-main-container py-4">

  <div class="row mb-3 align-items-center">
    <div class="col-md-8">
      <div class="lr-section-title mb-1">Data</div>
      <h1 class="lr-section-heading mb-1">Exports</h1>
      <p class="lr-stat-subtext mb-0">Filter first, then export the dataset you need.</p>
    </div>
    <div class="col-md-4 text-md-end mt-3 mt-md-0">
      <a class="btn btn-outline-light" href="<?= $BASE_URL ?>/admin/evaluation.php">
        <i class="fa-solid fa-chart-line me-2"></i>View Evaluation
      </a>
    </div>
  </div>

    <!-- Filters -->
    <div class="lr-card mb-3">
      <div class="lr-card-body">
        <form method="GET" class="row g-2 align-items-end">
          <div class="col-md-3">
            <label class="form-label lr-stat-label">From</label>
            <input class="form-control" type="date" name="from" value="<?= h($from) ?>">
          </div>
          <div class="col-md-3">
            <label class="form-label lr-stat-label">To</label>
            <input class="form-control" type="date" name="to" value="<?= h($to) ?>">
          </div>
          <div class="col-md-3">
            <label class="form-label lr-stat-label">Exercise</label>
            <select class="form-select" name="exercise">
              <option value="">All</option>
              <option value="bicep_curl" <?= $exercise==='bicep_curl'?'selected':'' ?>>Bicep Curl</option>
              <option value="shoulder_press" <?= $exercise==='shoulder_press'?'selected':'' ?>>Shoulder Press</option>
              <option value="lateral_raise" <?= $exercise==='lateral_raise'?'selected':'' ?>>Lateral Raise</option>
            </select>
          </div>
          <div class="col-md-3">
            <label class="form-label lr-stat-label">Fatigue</label>
            <select class="form-select" name="fatigue">
              <option value="">All</option>
              <option value="1" <?= $fatigue==='1'?'selected':'' ?>>Fatigue only</option>
              <option value="0" <?= $fatigue==='0'?'selected':'' ?>>Non-fatigue only</option>
            </select>
          </div>

          <div class="col-md-4">
            <label class="form-label lr-stat-label">Reviewed (sessions only)</label>
            <select class="form-select" name="reviewed">
              <option value="">All</option>
              <option value="1" <?= $reviewed==='1'?'selected':'' ?>>Reviewed only</option>
              <option value="0" <?= $reviewed==='0'?'selected':'' ?>>Unreviewed only</option>
            </select>
          </div>

          <div class="col-md-4 d-grid">
            <button class="btn btn-primary lr-btn-strong" type="submit">
              <i class="fa-solid fa-filter me-2"></i>Apply Filters
            </button>
          </div>

          <div class="col-md-4 d-grid">
            <a class="btn btn-outline-light" href="<?= $BASE_URL ?>/admin/exports.php">
              Clear Filters
            </a>
          </div>
        </form>

        <?php if ($active_filters): ?>
          <div class="lr-stat-subtext mt-3 mb-0">
            <strong>Active:</strong> <?= h(implode(" • ", $active_filters)) ?>
          </div>
        <?php else: ?>
          <div class="lr-stat-subtext mt-3 mb-0">
            No filters applied.
          </div>
        <?php endif; ?>

        <div class="lr-stat-subtext mt-2 mb-0">
          IDs and metrics only. No names or emails.
        </div>
      </div>
    </div>

    <!-- Preview counts -->
    <div class="row g-3 mb-3">
      <div class="col-md-6 col-lg-3">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Sessions matched</div>
            <div class="lr-stat-value mt-1"><?= (int)$counts['sessions'] ?></div>
            <div class="lr-stat-subtext">Max export: 5,000 rows.</div>
          </div>
        </div>
      </div>

      <div class="col-md-6 col-lg-3">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Rep metrics matched</div>
            <div class="lr-stat-value mt-1"><?= (int)$counts['rep_metrics'] ?></div>
            <div class="lr-stat-subtext">Max export: 20,000 rows.</div>
          </div>
        </div>
      </div>

      <div class="col-md-6 col-lg-3">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">SUS responses matched</div>
            <div class="lr-stat-value mt-1"><?= (int)$counts['sus'] ?></div>
            <div class="lr-stat-subtext">Max export: 20,000 rows.</div>
          </div>
        </div>
      </div>

      <div class="col-md-6 col-lg-3">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Expert reviews matched</div>
            <div class="lr-stat-value mt-1"><?= (int)$counts['expert_reviews'] ?></div>
            <div class="lr-stat-subtext">Max export: 20,000 rows.</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Export cards -->
    <div class="row g-3">
      <div class="col-md-6">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-section-title mb-1">Dataset</div>
            <div class="lr-section-heading mb-1">Sessions</div>
            <p class="lr-stat-subtext mb-3">
              Training logs with review status.
            </p>
            <div class="d-flex gap-2 flex-wrap">
              <a class="btn btn-primary lr-btn-strong" href="?download=sessions<?= h($qs) ?>">
                <i class="fa-solid fa-file-csv me-2"></i>Export Sessions CSV
              </a>
              <a class="btn btn-outline-light" href="<?= $BASE_URL ?>/admin/evaluation.php">
                <i class="fa-solid fa-chart-line me-2"></i>Evaluation
              </a>
            </div>
            <div class="lr-stat-subtext mt-3 mb-0">
              Includes IDs, exercise, rep totals, fatigue, processing time, date, and reviewed flag.
            </div>
          </div>
        </div>
      </div>

      <div class="col-md-6">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-section-title mb-1">Dataset</div>
            <div class="lr-section-heading mb-1">Rep Metrics</div>
            <p class="lr-stat-subtext mb-3">
              Per-rep movement measurements.
            </p>
            <a class="btn btn-primary lr-btn-strong" href="?download=rep_metrics<?= h($qs) ?>">
              <i class="fa-solid fa-file-csv me-2"></i>Export Rep Metrics CSV
            </a>
            <div class="lr-stat-subtext mt-3 mb-0">
              Includes rep index, duration, ROM, trunk sway, confidence, label, anomaly score, and date.
            </div>
          </div>
        </div>
      </div>

      <div class="col-md-6">
        <div class="lr-card h-100">
         <div class="lr-card-body">
          <div class="lr-section-title mb-1">Dataset</div>
          <div class="lr-section-heading mb-1">SUS Responses</div>
          <p class="lr-stat-subtext mb-3">
            Usability survey results.
          </p>
          <a class="btn btn-primary lr-btn-strong" href="?download=sus<?= h($qs) ?>">
            <i class="fa-solid fa-file-csv me-2"></i>Export SUS CSV
          </a>
          <div class="lr-stat-subtext mt-3 mb-0">
            Includes user ID, Q1 to Q10, SUS score, and date.
          </div>
        </div>
        </div>
      </div>

      <div class="col-md-6">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-section-title mb-1">Dataset</div>
            <div class="lr-section-heading mb-1">Expert Reviews</div>
            <p class="lr-stat-subtext mb-3">
              Trainer review records by session and exercise.
            </p>
            <a class="btn btn-primary lr-btn-strong" href="?download=expert_reviews<?= h($qs) ?>">
              <i class="fa-solid fa-file-csv me-2"></i>Export Expert Reviews CSV
            </a>
            <div class="lr-stat-subtext mt-3 mb-0">
              Includes trainer ID, rating, notes, marked good/bad reps, date, and exercise.
            </div>
          </div>
        </div>
      </div>
    </div>

  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>
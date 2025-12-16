<?php
// liftright/web/admin/exports.php (FILTERED)

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['admin']);
$page_title = "Exports";

if (!function_exists('h')) {
  function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
}

function csv_row(array $row): string {
  $out = [];
  foreach ($row as $v) {
    $s = (string)$v;
    $s = str_replace('"', '""', $s);
    $out[] = '"' . $s . '"';
  }
  return implode(",", $out) . "\r\n";
}

$download = (string)($_GET['download'] ?? '');

// filters
$from = trim((string)($_GET['from'] ?? ''));
$to   = trim((string)($_GET['to'] ?? ''));
$exercise = trim((string)($_GET['exercise'] ?? '')); // bicep_curl/shoulder_press/lateral_raise
$fatigue  = trim((string)($_GET['fatigue'] ?? ''));  // 1/0
$reviewed = trim((string)($_GET['reviewed'] ?? '')); // 1/0

$from_ok = preg_match('/^\d{4}-\d{2}-\d{2}$/', $from);
$to_ok   = preg_match('/^\d{4}-\d{2}-\d{2}$/', $to);
$exercise_ok = in_array($exercise, ['bicep_curl','shoulder_press','lateral_raise'], true);
$fatigue_ok = ($fatigue === '1' || $fatigue === '0');
$reviewed_ok = ($reviewed === '1' || $reviewed === '0');

if ($download !== '') {
  header('Content-Type: text/csv; charset=utf-8');
  header('Pragma: no-cache');
  header('Expires: 0');

  // --- SESSIONS EXPORT ---
  if ($download === 'sessions') {
    header('Content-Disposition: attachment; filename="liftright_sessions.csv"');

    echo csv_row(['log_id','user_id','full_name','exercise_type','source_type','reps_total','reps_good','reps_bad','fatigue_flag','processing_ms','created_at','reviewed']);

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
        l.log_id, l.user_id, u.full_name, l.exercise_type, l.source_type,
        l.reps_total, l.reps_good, l.reps_bad, l.fatigue_flag, l.processing_ms, l.created_at,
        CASE WHEN er.review_id IS NULL THEN 0 ELSE 1 END AS reviewed
      FROM training_logs l
      JOIN users u ON u.user_id = l.user_id
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
    header('Content-Disposition: attachment; filename="liftright_rep_metrics.csv"');
    echo csv_row(['rep_id','log_id','rep_index','duration_ms','rom_score','trunk_sway','confidence_avg','form_label','anomaly_score','created_at']);

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
    header('Content-Disposition: attachment; filename="liftright_sus_responses.csv"');
    echo csv_row(['sus_id','user_id','q1','q2','q3','q4','q5','q6','q7','q8','q9','q10','sus_score','created_at']);

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

  // --- EXPERT REVIEWS EXPORT ---
  if ($download === 'expert_reviews') {
    header('Content-Disposition: attachment; filename="liftright_expert_reviews.csv"');
    echo csv_row(['review_id','log_id','trainer_id','trainer_name','rating','notes','marked_good_reps','marked_bad_reps','created_at','exercise_type']);

    $where = "1=1";
    $types = "";
    $params = [];

    if ($from_ok) { $where .= " AND DATE(er.created_at) >= ?"; $types.="s"; $params[]=$from; }
    if ($to_ok)   { $where .= " AND DATE(er.created_at) <= ?"; $types.="s"; $params[]=$to; }
    if ($exercise_ok) { $where .= " AND l.exercise_type = ?"; $types.="s"; $params[]=$exercise; }

    $stmt = $mysqli->prepare("
      SELECT
        er.review_id, er.log_id, er.trainer_id, u.full_name AS trainer_name,
        er.rating, er.notes, er.marked_good_reps, er.marked_bad_reps, er.created_at,
        l.exercise_type
      FROM expert_reviews er
      JOIN users u ON u.user_id = er.trainer_id
      JOIN training_logs l ON l.log_id = er.log_id
      WHERE $where
      ORDER BY er.created_at DESC
      LIMIT 20000
    ");
    if ($types !== "") $stmt->bind_param($types, ...$params);
    $stmt->execute();
    $res = $stmt->get_result();
    while ($r = $res->fetch_assoc()) {
      $r['notes'] = str_replace(["\r","\n"], [' ',' '], (string)($r['notes'] ?? ''));
      echo csv_row($r);
    }
    $stmt->close();
    exit;
  }

  http_response_code(400);
  echo "Invalid export.";
  exit;
}

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="lr-page-wrapper">
  <div class="container lr-main-container py-4">

    <div class="row mb-3">
      <div class="col-md-8">
        <div class="lr-section-title mb-1">Data</div>
        <h1 class="lr-section-heading mb-1">Exports</h1>
        <p class="lr-stat-subtext mb-0">Download CSV datasets for reporting and analysis (admin-only).</p>
      </div>
    </div>

    <div class="lr-card mb-3">
      <div class="lr-card-body">
        <form method="GET" class="row g-2 align-items-end">
          <div class="col-md-3">
            <label class="form-label">From</label>
            <input class="form-control" name="from" value="<?= h($from) ?>" placeholder="YYYY-MM-DD">
          </div>
          <div class="col-md-3">
            <label class="form-label">To</label>
            <input class="form-control" name="to" value="<?= h($to) ?>" placeholder="YYYY-MM-DD">
          </div>
          <div class="col-md-3">
            <label class="form-label">Exercise</label>
            <select class="form-select" name="exercise">
              <option value="">All</option>
              <option value="bicep_curl" <?= $exercise==='bicep_curl'?'selected':'' ?>>Bicep Curl</option>
              <option value="shoulder_press" <?= $exercise==='shoulder_press'?'selected':'' ?>>Shoulder Press</option>
              <option value="lateral_raise" <?= $exercise==='lateral_raise'?'selected':'' ?>>Lateral Raise</option>
            </select>
          </div>
          <div class="col-md-3">
            <label class="form-label">Fatigue</label>
            <select class="form-select" name="fatigue">
              <option value="">All</option>
              <option value="1" <?= $fatigue==='1'?'selected':'' ?>>Fatigue only</option>
              <option value="0" <?= $fatigue==='0'?'selected':'' ?>>Non-fatigue only</option>
            </select>
          </div>

          <div class="col-md-3">
            <label class="form-label">Reviewed (sessions only)</label>
            <select class="form-select" name="reviewed">
              <option value="">All</option>
              <option value="1" <?= $reviewed==='1'?'selected':'' ?>>Reviewed only</option>
              <option value="0" <?= $reviewed==='0'?'selected':'' ?>>Unreviewed only</option>
            </select>
          </div>

          <div class="col-md-3 d-grid">
            <button class="btn btn-outline-light" type="submit">
              <i class="fa-solid fa-filter me-2"></i>Apply filters
            </button>
          </div>
        </form>

        <div class="lr-stat-subtext mt-2">
          Filters apply to downloads automatically.
        </div>
      </div>
    </div>

    <?php
      // keep filter query string for download links
      $qs = http_build_query([
        'from' => $from,
        'to' => $to,
        'exercise' => $exercise,
        'fatigue' => $fatigue,
        'reviewed' => $reviewed,
      ]);
      $qs = $qs ? '&' . $qs : '';
    ?>

    <div class="row g-3">
      <div class="col-md-6">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-section-heading mb-1">Sessions</div>
            <p class="lr-stat-subtext">Exports <code>training_logs</code> + user join + reviewed flag.</p>
            <a class="btn btn-primary" href="?download=sessions<?= h($qs) ?>">
              <i class="fa-solid fa-file-csv me-2"></i>Download sessions.csv
            </a>
          </div>
        </div>
      </div>

      <div class="col-md-6">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-section-heading mb-1">Rep Metrics</div>
            <p class="lr-stat-subtext">Exports <code>rep_metrics</code> (date filters apply).</p>
            <a class="btn btn-primary" href="?download=rep_metrics<?= h($qs) ?>">
              <i class="fa-solid fa-file-csv me-2"></i>Download rep_metrics.csv
            </a>
          </div>
        </div>
      </div>

      <div class="col-md-6">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-section-heading mb-1">SUS Responses</div>
            <p class="lr-stat-subtext">Exports <code>sus_responses</code> (date filters apply).</p>
            <a class="btn btn-primary" href="?download=sus<?= h($qs) ?>">
              <i class="fa-solid fa-file-csv me-2"></i>Download sus_responses.csv
            </a>
          </div>
        </div>
      </div>

      <div class="col-md-6">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-section-heading mb-1">Expert Reviews</div>
            <p class="lr-stat-subtext">Exports <code>expert_reviews</code> + exercise_type (exercise/date filters apply).</p>
            <a class="btn btn-primary" href="?download=expert_reviews<?= h($qs) ?>">
              <i class="fa-solid fa-file-csv me-2"></i>Download expert_reviews.csv
            </a>
          </div>
        </div>
      </div>
    </div>

  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>

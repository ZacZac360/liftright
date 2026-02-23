<?php
// liftright/web/admin/evaluation.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['admin']);
$page_title = "Evaluation Summary";

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

$from = trim((string)($_GET['from'] ?? ''));
$to   = trim((string)($_GET['to'] ?? ''));

// Basic date validation (YYYY-MM-DD)
$from_ok = preg_match('/^\d{4}-\d{2}-\d{2}$/', $from);
$to_ok   = preg_match('/^\d{4}-\d{2}-\d{2}$/', $to);

$where_logs = "1=1";
$types_logs = "";
$params_logs = [];

$where_sus = "1=1";
$types_sus = "";
$params_sus = [];

$where_reviews = "1=1";
$types_reviews = "";
$params_reviews = [];

if ($from_ok) {
  $where_logs .= " AND DATE(l.created_at) >= ?";
  $types_logs .= "s";
  $params_logs[] = $from;

  $where_sus .= " AND DATE(created_at) >= ?";
  $types_sus .= "s";
  $params_sus[] = $from;

  $where_reviews .= " AND DATE(er.created_at) >= ?";
  $types_reviews .= "s";
  $params_reviews[] = $from;
}
if ($to_ok) {
  $where_logs .= " AND DATE(l.created_at) <= ?";
  $types_logs .= "s";
  $params_logs[] = $to;

  $where_sus .= " AND DATE(created_at) <= ?";
  $types_sus .= "s";
  $params_sus[] = $to;

  $where_reviews .= " AND DATE(er.created_at) <= ?";
  $types_reviews .= "s";
  $params_reviews[] = $to;
}

/**
 * 1) Global Session Stats
 */
$stats = [
  'sessions_total' => 0,
  'fatigue_rate' => 0,
  'avg_accuracy' => 0,
  'avg_processing_ms' => 0,
  'review_coverage' => 0,
];

$stmt = $mysqli->prepare("
  SELECT
    COUNT(*) AS sessions_total,
    AVG(CASE WHEN l.reps_total > 0 THEN (l.reps_good / l.reps_total) * 100 ELSE NULL END) AS avg_accuracy,
    AVG(CASE WHEN l.fatigue_flag=1 THEN 1 ELSE 0 END) AS fatigue_rate,
    AVG(l.processing_ms) AS avg_processing_ms
  FROM training_logs l
  WHERE $where_logs
");
if ($types_logs !== "") $stmt->bind_param($types_logs, ...$params_logs);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

$stats['sessions_total'] = (int)($row['sessions_total'] ?? 0);
$stats['avg_accuracy'] = (int)round((float)($row['avg_accuracy'] ?? 0));
$stats['fatigue_rate'] = (int)round(((float)($row['fatigue_rate'] ?? 0)) * 100);
$stats['avg_processing_ms'] = (int)round((float)($row['avg_processing_ms'] ?? 0));

$stmt = $mysqli->prepare("
  SELECT
    COUNT(DISTINCT l.log_id) AS total_logs,
    SUM(CASE WHEN er.review_id IS NOT NULL THEN 1 ELSE 0 END) AS reviewed_logs
  FROM training_logs l
  LEFT JOIN expert_reviews er ON er.log_id = l.log_id
  WHERE $where_logs
");
if ($types_logs !== "") $stmt->bind_param($types_logs, ...$params_logs);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

$total_logs = (int)($row['total_logs'] ?? 0);
$reviewed_logs = (int)($row['reviewed_logs'] ?? 0);
$stats['review_coverage'] = ($total_logs > 0) ? (int)round(($reviewed_logs / $total_logs) * 100) : 0;

/**
 * 2) Sessions by Exercise (accuracy + fatigue)
 */
$by_exercise = [];
$stmt = $mysqli->prepare("
  SELECT
    l.exercise_type,
    COUNT(*) AS sessions,
    AVG(CASE WHEN l.reps_total > 0 THEN (l.reps_good / l.reps_total) * 100 ELSE NULL END) AS avg_accuracy,
    AVG(CASE WHEN l.fatigue_flag=1 THEN 1 ELSE 0 END) AS fatigue_rate
  FROM training_logs l
  WHERE $where_logs
  GROUP BY l.exercise_type
  ORDER BY sessions DESC
");
if ($types_logs !== "") $stmt->bind_param($types_logs, ...$params_logs);
$stmt->execute();
$res = $stmt->get_result();
while ($r = $res->fetch_assoc()) $by_exercise[] = $r;
$stmt->close();

/**
 * 3) SUS Summary
 */
$sus = [
  'count' => 0,
  'mean' => 0,
];
$stmt = $mysqli->prepare("
  SELECT COUNT(*) AS c, AVG(sus_score) AS mean_score
  FROM sus_responses
  WHERE $where_sus
");
if ($types_sus !== "") $stmt->bind_param($types_sus, ...$params_sus);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

$sus['count'] = (int)($row['c'] ?? 0);
$sus['mean']  = (int)round((float)($row['mean_score'] ?? 0));

/**
 * 4) Expert Reviews Summary + by exercise
 */
$reviews = [
  'count' => 0,
  'mean_rating' => 0,
];
$stmt = $mysqli->prepare("
  SELECT COUNT(*) AS c, AVG(rating) AS mean_rating
  FROM expert_reviews er
  WHERE $where_reviews
");
if ($types_reviews !== "") $stmt->bind_param($types_reviews, ...$params_reviews);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

$reviews['count'] = (int)($row['c'] ?? 0);
$reviews['mean_rating'] = (int)round((float)($row['mean_rating'] ?? 0));

$reviews_by_ex = [];
$stmt = $mysqli->prepare("
  SELECT
    l.exercise_type,
    COUNT(*) AS reviews,
    AVG(er.rating) AS avg_rating
  FROM expert_reviews er
  JOIN training_logs l ON l.log_id = er.log_id
  WHERE $where_reviews
  GROUP BY l.exercise_type
  ORDER BY reviews DESC
");
if ($types_reviews !== "") $stmt->bind_param($types_reviews, ...$params_reviews);
$stmt->execute();
$res = $stmt->get_result();
while ($r = $res->fetch_assoc()) $reviews_by_ex[] = $r;
$stmt->close();

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="lr-page-wrapper">
  <div class="container lr-main-container py-4">

    <div class="row mb-3 align-items-center">
      <div class="col-md-8">
        <div class="lr-section-title mb-1">Administration</div>
        <h1 class="lr-section-heading mb-1">Evaluation Summary</h1>
        <p class="lr-stat-subtext mb-0">System-wide usability + expert evaluation + performance KPIs.</p>
      </div>
    </div>

    <div class="lr-card mb-3">
      <div class="lr-card-body">
        <form method="GET" class="row g-2">
          <div class="col-md-4">
            <label class="form-label">From (YYYY-MM-DD)</label>
            <input class="form-control" name="from" value="<?= h($from) ?>" placeholder="2025-01-01">
          </div>
          <div class="col-md-4">
            <label class="form-label">To (YYYY-MM-DD)</label>
            <input class="form-control" name="to" value="<?= h($to) ?>" placeholder="2025-12-31">
          </div>
          <div class="col-md-4 d-grid align-items-end">
            <button class="btn btn-primary mt-4" type="submit">
              <i class="fa-solid fa-filter me-2"></i>Apply
            </button>
          </div>
        </form>
      </div>
    </div>

    <div class="row g-3 mb-3">
      <div class="col-md-6 col-lg-3">
        <div class="lr-card h-100"><div class="lr-card-body">
          <div class="lr-stat-label">Sessions</div>
          <div class="lr-stat-value mt-1"><?= (int)$stats['sessions_total'] ?></div>
          <div class="lr-stat-subtext">Total processed (filtered range).</div>
        </div></div>
      </div>

      <div class="col-md-6 col-lg-3">
        <div class="lr-card h-100"><div class="lr-card-body">
          <div class="lr-stat-label">Avg report accuracy</div>
          <div class="lr-stat-value mt-1"><?= (int)$stats['avg_accuracy'] ?>%</div>
          <div class="lr-stat-subtext">Computed from good/total reps.</div>
        </div></div>
      </div>

      <div class="col-md-6 col-lg-3">
        <div class="lr-card h-100"><div class="lr-card-body">
          <div class="lr-stat-label">Fatigue rate</div>
          <div class="lr-stat-value mt-1"><?= (int)$stats['fatigue_rate'] ?>%</div>
          <div class="lr-stat-subtext">Percent of sessions flagged.</div>
        </div></div>
      </div>

      <div class="col-md-6 col-lg-3">
        <div class="lr-card h-100"><div class="lr-card-body">
          <div class="lr-stat-label">Review coverage</div>
          <div class="lr-stat-value mt-1"><?= (int)$stats['review_coverage'] ?>%</div>
          <div class="lr-stat-subtext">Sessions with expert review.</div>
        </div></div>
      </div>
    </div>

    <div class="row g-3 mb-3">
      <div class="col-lg-6">
        <div class="lr-card h-100">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">Sessions</div>
            <div class="lr-section-heading mb-0">By Exercise</div>
          </div>
          <div class="lr-card-body p-0">
            <div class="table-responsive">
              <table class="table table-hover table-striped align-middle mb-0 table-lr-dark">
                <thead>
                  <tr>
                    <th>Exercise</th>
                    <th>Sessions</th>
                    <th>Avg Accuracy</th>
                    <th>Fatigue Rate</th>
                  </tr>
                </thead>
                <tbody>
                <?php if (!$by_exercise): ?>
                  <tr><td colspan="4" class="text-center py-4 lr-stat-subtext">No data.</td></tr>
                <?php else: ?>
                  <?php foreach ($by_exercise as $r): ?>
                    <tr>
                      <td><?= h(formatExercise((string)$r['exercise_type'])) ?></td>
                      <td><?= (int)$r['sessions'] ?></td>
                      <td><?= (int)round((float)$r['avg_accuracy']) ?>%</td>
                      <td><?= (int)round(((float)$r['fatigue_rate']) * 100) ?>%</td>
                    </tr>
                  <?php endforeach; ?>
                <?php endif; ?>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      <div class="col-lg-6">
        <div class="lr-card h-100">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">Evaluation</div>
            <div class="lr-section-heading mb-0">SUS + Expert Reviews</div>
          </div>
          <div class="lr-card-body">
            <div class="row g-3">
              <div class="col-md-6">
                <div class="lr-card h-100"><div class="lr-card-body">
                  <div class="lr-stat-label">SUS responses</div>
                  <div class="lr-stat-value mt-1"><?= (int)$sus['count'] ?></div>
                  <div class="lr-stat-subtext">Mean SUS: <strong><?= (int)$sus['mean'] ?></strong></div>
                </div></div>
              </div>

              <div class="col-md-6">
                <div class="lr-card h-100"><div class="lr-card-body">
                  <div class="lr-stat-label">Expert reviews</div>
                  <div class="lr-stat-value mt-1"><?= (int)$reviews['count'] ?></div>
                  <div class="lr-stat-subtext">Avg rating: <strong><?= (int)$reviews['mean_rating'] ?>/5</strong></div>
                </div></div>
              </div>

              <div class="col-12">
                <div class="lr-section-title mb-1">Expert rating by exercise</div>
                <div class="table-responsive">
                  <table class="table table-hover table-striped align-middle mb-0 table-lr-dark">
                    <thead>
                      <tr>
                        <th>Exercise</th>
                        <th>Reviews</th>
                        <th>Avg Rating</th>
                      </tr>
                    </thead>
                    <tbody>
                    <?php if (!$reviews_by_ex): ?>
                      <tr><td colspan="3" class="text-center py-3 lr-stat-subtext">No reviews yet.</td></tr>
                    <?php else: ?>
                      <?php foreach ($reviews_by_ex as $r): ?>
                        <tr>
                          <td><?= h(formatExercise((string)$r['exercise_type'])) ?></td>
                          <td><?= (int)$r['reviews'] ?></td>
                          <td><?= (int)round((float)$r['avg_rating']) ?>/5</td>
                        </tr>
                      <?php endforeach; ?>
                    <?php endif; ?>
                    </tbody>
                  </table>
                </div>
              </div>

              <div class="col-12">
                <div class="lr-stat-subtext mt-2">
                  Tip: This page is perfect for Chapter 4 tables (SUS mean, expert mean, fatigue rate, accuracy per exercise).
                </div>
              </div>

            </div>
          </div>
        </div>
      </div>

    </div>

  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>

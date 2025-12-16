<?php
// liftright/web/coach/reviews.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['trainer']);
$page_title = "Coach Reviews";

$exercise = trim((string)($_GET['exercise'] ?? ''));
$fatigue  = trim((string)($_GET['fatigue'] ?? ''));
$review   = trim((string)($_GET['review'] ?? '')); // pending|reviewed
$q        = trim((string)($_GET['q'] ?? ''));

$allowedExercises = ['bicep_curl','shoulder_press','lateral_raise'];
$exercise = in_array($exercise, $allowedExercises, true) ? $exercise : '';

$allowedFatigue = ['0','1'];
$fatigue = in_array($fatigue, $allowedFatigue, true) ? $fatigue : '';

$allowedReview = ['pending','reviewed'];
$review = in_array($review, $allowedReview, true) ? $review : '';

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
function reviewBadge(bool $reviewed): string {
  return $reviewed ? 'lr-badge lr-badge-good' : 'lr-badge lr-badge-warning';
}

$sql = "
  SELECT
    tl.log_id,
    tl.created_at,
    tl.exercise_type,
    tl.source_type,
    tl.reps_total,
    tl.reps_good,
    tl.reps_bad,
    tl.form_error_count,
    tl.fatigue_flag,
    tl.processing_ms,
    u.user_id AS trainee_id,
    u.full_name AS trainee_name,
    u.email AS trainee_email,
    EXISTS(
      SELECT 1 FROM expert_reviews er
      WHERE er.log_id = tl.log_id
      LIMIT 1
    ) AS is_reviewed
  FROM training_logs tl
  JOIN users u ON u.user_id = tl.user_id
  WHERE 1=1
";

$types = "";
$params = [];

if ($exercise !== '') {
  $sql .= " AND tl.exercise_type = ? ";
  $types .= "s";
  $params[] = $exercise;
}
if ($fatigue !== '') {
  $sql .= " AND tl.fatigue_flag = ? ";
  $types .= "i";
  $params[] = (int)$fatigue;
}
if ($q !== '') {
  $sql .= " AND (u.full_name LIKE CONCAT('%', ?, '%') OR u.email LIKE CONCAT('%', ?, '%')) ";
  $types .= "ss";
  $params[] = $q;
  $params[] = $q;
}

// Review filter using HAVING (because is_reviewed is computed)
if ($review === 'pending') {
  $sql .= " HAVING is_reviewed = 0 ";
} elseif ($review === 'reviewed') {
  $sql .= " HAVING is_reviewed = 1 ";
}

$sql .= " ORDER BY tl.created_at DESC LIMIT 200";

$stmt = $mysqli->prepare($sql);
if ($types !== "") {
  $stmt->bind_param($types, ...$params);
}
$stmt->execute();
$res = $stmt->get_result();

$sessions = [];
while ($row = $res->fetch_assoc()) $sessions[] = $row;
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
        <div class="lr-section-title mb-1">Coach</div>
        <h1 class="lr-section-heading mb-1">Session Reviews</h1>
        <p class="lr-stat-subtext mb-0">Filter sessions and open a detailed view to submit an expert review.</p>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0">
        <a class="btn btn-outline-light btn-sm" href="<?= $BASE_URL ?>/coach/dashboard.php">Back to Dashboard</a>
      </div>
    </div>

    <!-- Filters -->
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
            <label class="form-label lr-stat-label">Fatigue</label>
            <select class="form-select" name="fatigue">
              <option value="">All</option>
              <option value="0" <?= $fatigue==='0'?'selected':'' ?>>Normal</option>
              <option value="1" <?= $fatigue==='1'?'selected':'' ?>>Warning</option>
            </select>
          </div>

          <div class="col-md-2">
            <label class="form-label lr-stat-label">Review</label>
            <select class="form-select" name="review">
              <option value="">All</option>
              <option value="pending" <?= $review==='pending'?'selected':'' ?>>Pending</option>
              <option value="reviewed" <?= $review==='reviewed'?'selected':'' ?>>Reviewed</option>
            </select>
          </div>

          <div class="col-md-3">
            <label class="form-label lr-stat-label">Search trainee</label>
            <input class="form-control" name="q" placeholder="name / email..." value="<?= h($q) ?>">
          </div>

          <div class="col-md-2 d-grid">
            <button class="btn btn-outline-light">Apply</button>
          </div>
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
        <div class="lr-stat-subtext mb-0"><?= count($sessions) ?> shown</div>
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
                <th></th>
              </tr>
            </thead>
            <tbody>
            <?php if (!$sessions): ?>
              <tr>
                <td colspan="9" class="text-center py-4 lr-stat-subtext">No sessions found.</td>
              </tr>
            <?php else: ?>
              <?php foreach ($sessions as $s):
                $total = (int)$s['reps_total'];
                $good  = (int)$s['reps_good'];
                $pct   = formPct($good, $total);
                $reviewed = ((int)$s['is_reviewed'] === 1);
              ?>
                <tr>
                  <td><?= h(date("M d, Y • g:i A", strtotime((string)$s['created_at']))) ?></td>
                  <td>
                    <div class="fw-semibold"><?= h((string)$s['trainee_name']) ?></div>
                    <div class="lr-stat-subtext"><?= h((string)$s['trainee_email']) ?></div>
                  </td>
                  <td><span class="lr-chip-exercise"><?= h(formatExercise((string)$s['exercise_type'])) ?></span></td>
                  <td><?= (int)$good ?> good / <?= (int)$total ?> total</td>
                  <td><span class="<?= h(formBadge($pct)) ?>"><?= (int)$pct ?>%</span></td>
                  <td>
                    <span class="<?= h(fatigueBadge((int)$s['fatigue_flag'])) ?>">
                      <?= ((int)$s['fatigue_flag'] === 1) ? 'Warning' : 'Normal' ?>
                    </span>
                  </td>
                  <td>
                    <span class="<?= h(reviewBadge($reviewed)) ?>">
                      <?= $reviewed ? 'Reviewed' : 'Pending' ?>
                    </span>
                  </td>
                  <td class="text-end">
                    <?= $s['processing_ms'] === null ? '—' : h((string)$s['processing_ms'] . ' ms') ?>
                  </td>
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

      <div class="lr-card-body">
        <div class="lr-stat-subtext mb-0">
          Next file: <strong>coach/review-session.php</strong> (per-session breakdown + submit expert review).
        </div>
      </div>
    </div>

  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>

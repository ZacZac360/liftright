<?php
// liftright/web/coach/review-session.php

session_start();

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['trainer']);
$page_title = "Review Session";

$trainer_id = (int)($_SESSION['user_id'] ?? 0);

$log_id = isset($_GET['log_id']) ? (int)$_GET['log_id'] : 0;
if ($log_id <= 0) {
  header("Location: {$BASE_URL}/coach/reviews.php");
  exit;
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
function fatigueBadge(int $flag): string {
  return $flag ? 'lr-badge lr-badge-warning' : 'lr-badge lr-badge-good';
}
function fmtDT(?string $dt): string {
  if (!$dt) return "—";
  $ts = strtotime($dt);
  return $ts ? date("M d, Y • g:i A", $ts) : $dt;
}

$errors = [];
$success = null;

/**
 * 1) Load SESSION from training_logs (main record)
 */
$stmt = $mysqli->prepare("
  SELECT
    tl.log_id,
    tl.user_id,
    tl.exercise_type,
    tl.source_type,
    tl.reps_total,
    tl.reps_good,
    tl.reps_bad,
    tl.form_error_count,
    tl.fatigue_flag,
    tl.processing_ms,
    tl.created_at,
    u.full_name AS trainee_name,
    u.email AS trainee_email
  FROM training_logs tl
  LEFT JOIN users u ON u.user_id = tl.user_id
  WHERE tl.log_id = ?
  LIMIT 1
");
$stmt->bind_param("i", $log_id);
$stmt->execute();
$session = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$session) {
  // If this happens, the log_id isn't in training_logs
  header("Location: {$BASE_URL}/coach/reviews.php");
  exit;
}

if (empty($session['trainee_name'])) $session['trainee_name'] = 'Unknown Trainee';
if (empty($session['trainee_email'])) $session['trainee_email'] = '—';

/**
 * 2) Rep metrics
 */
$reps = [];
$stmt = $mysqli->prepare("
  SELECT rep_id, rep_index, duration_ms, rom_score, trunk_sway, confidence_avg, form_label, anomaly_score, created_at
  FROM rep_metrics
  WHERE log_id = ?
  ORDER BY rep_index ASC
");
$stmt->bind_param("i", $log_id);
$stmt->execute();
$res = $stmt->get_result();
while ($r = $res->fetch_assoc()) $reps[] = $r;
$stmt->close();

/**
 * 3) Feedback
 */
$feedback = [];
$stmt = $mysqli->prepare("
  SELECT feedback_id, feedback_type, severity, feedback_text, created_at
  FROM feedback
  WHERE log_id = ?
  ORDER BY created_at ASC, feedback_id ASC
");
$stmt->bind_param("i", $log_id);
$stmt->execute();
$res = $stmt->get_result();
while ($r = $res->fetch_assoc()) $feedback[] = $r;
$stmt->close();

/**
 * 4) Existing expert review (if any)
 */
$existing_review = null;
$stmt = $mysqli->prepare("
  SELECT review_id, trainer_id, rating, notes, marked_good_reps, marked_bad_reps, created_at
  FROM expert_reviews
  WHERE log_id = ?
  ORDER BY created_at DESC
  LIMIT 1
");
$stmt->bind_param("i", $log_id);
$stmt->execute();
$existing_review = $stmt->get_result()->fetch_assoc();
$stmt->close();

/**
 * 5) Submit expert review (insert-only for prototype)
 */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $rating = isset($_POST['rating']) ? (int)$_POST['rating'] : 0;
  $notes  = trim((string)($_POST['review_notes'] ?? ''));

  if ($rating < 1 || $rating > 5) $errors[] = "Please provide a rating (1–5).";
  if (mb_strlen($notes) > 2000) $errors[] = "Review notes are too long.";
  if ($existing_review) $errors[] = "This session already has an expert review saved.";

  if (!$errors) {
    $stmt = $mysqli->prepare("
      INSERT INTO expert_reviews (log_id, trainer_id, rating, notes, created_at)
      VALUES (?, ?, ?, ?, NOW())
    ");
    $stmt->bind_param("iiis", $log_id, $trainer_id, $rating, $notes);
    $stmt->execute();
    $stmt->close();

    // reload existing review
    $stmt = $mysqli->prepare("
      SELECT review_id, trainer_id, rating, notes, marked_good_reps, marked_bad_reps, created_at
      FROM expert_reviews
      WHERE log_id = ?
      ORDER BY created_at DESC
      LIMIT 1
    ");
    $stmt->bind_param("i", $log_id);
    $stmt->execute();
    $existing_review = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    $success = "Expert review saved successfully.";
  }
}

$total = (int)($session['reps_total'] ?? 0);
$good  = (int)($session['reps_good'] ?? 0);
$pct   = formPct($good, $total);

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="lr-page-wrapper">
  <div class="container lr-main-container py-4">

    <!-- Header -->
    <div class="row mb-3 align-items-center">
      <div class="col-md-8">
        <div class="lr-section-title mb-1">Coach Review</div>
        <h1 class="lr-section-heading mb-1">Session #<?= (int)$log_id ?></h1>
        <p class="lr-stat-subtext mb-0">Review AI results and submit an expert rating for evaluation.</p>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0">
        <a class="btn btn-outline-light btn-sm" href="<?= $BASE_URL ?>/coach/reviews.php">Back to Reviews</a>
      </div>
    </div>

    <?php if ($errors): ?>
      <div class="alert alert-danger">
        <div class="fw-semibold mb-1">Please fix the following:</div>
        <ul class="mb-0">
          <?php foreach ($errors as $e): ?><li><?= h($e) ?></li><?php endforeach; ?>
        </ul>
      </div>
    <?php endif; ?>

    <?php if ($success): ?>
      <div class="alert alert-success d-flex justify-content-between align-items-center">
        <div class="fw-semibold"><?= h($success) ?></div>
        <span class="lr-badge lr-badge-good">Saved</span>
      </div>
    <?php endif; ?>

    <!-- Session summary -->
    <div class="row g-3 mb-4">
      <div class="col-lg-4">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Trainee</div>
            <div class="fw-semibold fs-5"><?= h((string)$session['trainee_name']) ?></div>
            <div class="lr-stat-subtext"><?= h((string)$session['trainee_email']) ?></div>
            <hr class="border-secondary my-3">
            <div class="lr-stat-label">Exercise</div>
            <div><span class="lr-chip-exercise"><?= h(formatExercise((string)$session['exercise_type'])) ?></span></div>
            <div class="lr-stat-subtext mt-2">Date: <?= h(fmtDT((string)$session['created_at'])) ?></div>
          </div>
        </div>
      </div>

      <div class="col-lg-4">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Form score</div>
            <div class="d-flex align-items-center gap-2 mt-1">
              <div class="lr-stat-value"><?= (int)$pct ?>%</div>
              <span class="<?= h(formBadge($pct)) ?>"><?= (int)$pct ?>%</span>
            </div>
            <div class="lr-stat-subtext mt-2"><?= (int)$good ?> good / <?= (int)$total ?> total reps</div>
            <hr class="border-secondary my-3">
            <div class="lr-stat-label">Fatigue flag</div>
            <div class="mt-1">
              <span class="<?= h(fatigueBadge((int)$session['fatigue_flag'])) ?>">
                <?= ((int)$session['fatigue_flag'] === 1) ? 'Warning' : 'Normal' ?>
              </span>
            </div>
          </div>
        </div>
      </div>

      <div class="col-lg-4">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Latency</div>
            <div class="lr-stat-value mt-1">
              <?= $session['processing_ms'] === null ? '—' : h((string)$session['processing_ms'] . ' ms') ?>
            </div>
            <div class="lr-stat-subtext">Python processing time saved on finish.</div>
            <hr class="border-secondary my-3">
            <div class="lr-stat-label">Errors counted</div>
            <div class="lr-stat-value mt-1"><?= (int)($session['form_error_count'] ?? 0) ?></div>
            <div class="lr-stat-subtext">Total form_error_count.</div>
          </div>
        </div>
      </div>
    </div>

    <div class="row g-4">

      <!-- Rep table -->
      <div class="col-lg-8">
        <div class="lr-card">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">Details</div>
            <div class="lr-section-heading mb-0">Rep metrics</div>
          </div>
          <div class="lr-card-body p-0">
            <div class="table-responsive">
              <table class="table table-hover table-striped align-middle mb-0 table-lr-dark">
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Label</th>
                    <th class="text-end">Duration</th>
                    <th class="text-end">ROM</th>
                    <th class="text-end">Sway</th>
                    <th class="text-end">Confidence</th>
                    <th class="text-end">Anomaly</th>
                  </tr>
                </thead>
                <tbody>
                  <?php if (!$reps): ?>
                    <tr><td colspan="7" class="text-center py-4 lr-stat-subtext">No rep metrics recorded.</td></tr>
                  <?php else: ?>
                    <?php foreach ($reps as $r): ?>
                      <tr>
                        <td><?= (int)$r['rep_index'] ?></td>
                        <td class="text-capitalize"><?= h((string)$r['form_label']) ?></td>
                        <td class="text-end"><?= $r['duration_ms'] === null ? '—' : (int)$r['duration_ms'] . ' ms' ?></td>
                        <td class="text-end"><?= $r['rom_score'] === null ? '—' : h(number_format((float)$r['rom_score'], 2)) ?></td>
                        <td class="text-end"><?= $r['trunk_sway'] === null ? '—' : h(number_format((float)$r['trunk_sway'], 3)) ?></td>
                        <td class="text-end"><?= $r['confidence_avg'] === null ? '—' : h(number_format((float)$r['confidence_avg'], 2)) ?></td>
                        <td class="text-end"><?= $r['anomaly_score'] === null ? '—' : h(number_format((float)$r['anomaly_score'], 3)) ?></td>
                      </tr>
                    <?php endforeach; ?>
                  <?php endif; ?>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <!-- Feedback -->
        <div class="lr-card mt-4">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">AI Output</div>
            <div class="lr-section-heading mb-0">Feedback messages</div>
          </div>
          <div class="lr-card-body">
            <?php if (!$feedback): ?>
              <div class="lr-stat-subtext">No feedback messages recorded.</div>
            <?php else: ?>
              <div class="list-group list-group-flush">
                <?php foreach ($feedback as $f): ?>
                  <div class="list-group-item bg-transparent text-white border-secondary">
                    <div class="d-flex justify-content-between align-items-center">
                      <div class="fw-semibold text-capitalize">
                        <?= h((string)$f['feedback_type']) ?> • <?= h((string)$f['severity']) ?>
                      </div>
                      <div class="lr-stat-subtext"><?= h(fmtDT((string)$f['created_at'])) ?></div>
                    </div>
                    <div class="lr-stat-subtext mt-1"><?= h((string)$f['feedback_text']) ?></div>
                  </div>
                <?php endforeach; ?>
              </div>
            <?php endif; ?>
          </div>
        </div>
      </div>

      <!-- Review form -->
      <div class="col-lg-4">
        <div class="lr-card">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">Evaluation</div>
            <div class="lr-section-heading mb-0">Expert review</div>
          </div>
          <div class="lr-card-body">

            <?php if ($existing_review): ?>
              <div class="alert alert-success mb-3">
                <div class="fw-semibold">Review already submitted</div>
                <div class="lr-stat-subtext mb-0">
                  Rating: <strong><?= (int)$existing_review['rating'] ?>/5</strong> • <?= h(fmtDT((string)$existing_review['created_at'])) ?>
                </div>
              </div>

              <div class="lr-stat-label">Notes</div>
              <div class="lr-stat-subtext" style="white-space:pre-wrap;"><?= h((string)$existing_review['notes']) ?></div>

            <?php else: ?>
              <form method="POST">
                <label class="form-label lr-stat-label">Rating (1–5)</label>
                <select class="form-select mb-3" name="rating" required>
                  <option value="">Select...</option>
                  <option value="5">5 — Excellent</option>
                  <option value="4">4 — Good</option>
                  <option value="3">3 — Okay</option>
                  <option value="2">2 — Poor</option>
                  <option value="1">1 — Very poor</option>
                </select>

                <label class="form-label lr-stat-label">Review notes (optional)</label>
                <textarea class="form-control mb-3" name="review_notes" rows="6"
                          placeholder="Comment on form assessment accuracy, fatigue flag accuracy, any notable issues..."></textarea>

                <button class="btn btn-primary w-100" type="submit">Submit Expert Review</button>

                <div class="lr-stat-subtext mt-3 mb-0">
                  Prototype rule: one expert review per session (no editing yet).
                </div>
              </form>
            <?php endif; ?>

          </div>
        </div>
      </div>

    </div>

  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>

<?php
// liftright/web/coach/review-history.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['trainer']);
$page_title = "My Review History";

$trainer_id = (int)($_SESSION['user_id'] ?? 0);

function formatExercise(string $ex): string {
  return match($ex) {
    'shoulder_press' => 'Shoulder Press',
    'bicep_curl'     => 'Bicep Curl',
    'lateral_raise'  => 'Lateral Raise',
    default          => ucwords(str_replace('_',' ', $ex)),
  };
}
function fmtDT(?string $dt): string {
  if (!$dt) return "—";
  $ts = strtotime($dt);
  return $ts ? date("M d, Y • g:i A", $ts) : $dt;
}

$reviews = [];

$stmt = $mysqli->prepare("
  SELECT
    er.review_id,
    er.log_id,
    er.rating,
    er.notes,
    er.created_at AS reviewed_at,
    tl.exercise_type,
    tl.created_at AS session_date,
    u.full_name AS trainee_name,
    u.email AS trainee_email
  FROM expert_reviews er
  LEFT JOIN training_logs tl ON tl.log_id = er.log_id
  LEFT JOIN users u ON u.user_id = tl.user_id
  WHERE er.trainer_id = ?
  ORDER BY er.created_at DESC
  LIMIT 200
");
$stmt->bind_param("i", $trainer_id);
$stmt->execute();
$res = $stmt->get_result();
while ($r = $res->fetch_assoc()) $reviews[] = $r;
$stmt->close();

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="lr-page-wrapper">
  <div class="container lr-main-container py-4">

    <div class="row mb-4 align-items-center">
      <div class="col-md-8">
        <div class="lr-section-title mb-1">Coach</div>
        <h1 class="lr-section-heading mb-1">My Review History</h1>
        <p class="lr-stat-subtext mb-0">All expert reviews you have submitted (latest first).</p>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0">
        <a class="btn btn-outline-light btn-sm" href="<?= $BASE_URL ?>/coach/dashboard.php">Back to Dashboard</a>
      </div>
    </div>

    <div class="lr-card">
      <div class="lr-card-header d-flex justify-content-between align-items-center">
        <div>
          <div class="lr-section-title mb-1">Reviews</div>
          <div class="lr-section-heading mb-0">Submitted evaluations</div>
        </div>
        <div class="lr-stat-subtext mb-0"><?= count($reviews) ?> shown</div>
      </div>

      <div class="lr-card-body p-0">
        <div class="table-responsive">
          <table class="table table-hover table-striped align-middle mb-0 table-lr-dark">
            <thead>
              <tr>
                <th>Reviewed</th>
                <th>Trainee</th>
                <th>Session</th>
                <th>Exercise</th>
                <th class="text-end">Rating</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
            <?php if (!$reviews): ?>
              <tr>
                <td colspan="6" class="text-center py-4 lr-stat-subtext">No reviews submitted yet.</td>
              </tr>
            <?php else: ?>
              <?php foreach ($reviews as $r): ?>
                <tr>
                  <td><?= h(fmtDT((string)$r['reviewed_at'])) ?></td>
                  <td>
                    <div class="fw-semibold"><?= h((string)($r['trainee_name'] ?? 'Unknown Trainee')) ?></div>
                    <div class="lr-stat-subtext"><?= h((string)($r['trainee_email'] ?? '—')) ?></div>
                  </td>
                  <td><?= h(fmtDT((string)$r['session_date'])) ?></td>
                  <td><span class="lr-chip-exercise"><?= h(formatExercise((string)($r['exercise_type'] ?? 'unknown'))) ?></span></td>
                  <td class="text-end"><span class="lr-badge lr-badge-good"><?= (int)$r['rating'] ?>/5</span></td>
                  <td class="text-end">
                    <a class="btn btn-sm btn-outline-light"
                       href="<?= $BASE_URL ?>/coach/review-session.php?log_id=<?= (int)$r['log_id'] ?>">
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

      <?php if ($reviews): ?>
      <div class="lr-card-body">
        <div class="lr-stat-subtext mb-0">
          Notes are stored (for evaluation), but not shown in the table to keep it clean. Open any row to view details.
        </div>
      </div>
      <?php endif; ?>

    </div>

  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>

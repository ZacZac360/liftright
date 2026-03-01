<?php
// liftright/web/coach/reviews.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['trainer']);
$page_title = "My Reviews";

$trainer_id = (int)$_SESSION['user_id'];
$err = '';
$msg = '';

/* =========================================================
   HANDLE FLAG SUBMIT
========================================================= */

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['flag_review'])) {

  $review_id = (int)($_POST['review_id'] ?? 0);
  $reason = trim($_POST['reason'] ?? '');
  $details = trim($_POST['details'] ?? '');

  if ($review_id <= 0 || $reason === '') {
    $err = "Invalid flag submission.";
  } else {

    $stmt = $mysqli->prepare("
      INSERT INTO trainer_review_flags (review_id, trainer_id, reason, details)
      VALUES (?, ?, ?, ?)
    ");
    $stmt->bind_param("iiss", $review_id, $trainer_id, $reason, $details);
    $stmt->execute();
    $stmt->close();

    $msg = "Review flagged for admin review.";
  }
}

/* =========================================================
   LOAD REVIEWS
========================================================= */

$stmt = $mysqli->prepare("
  SELECT r.review_id, r.rating, r.review_text, r.created_at,
         u.full_name AS trainee_name
  FROM trainer_reviews r
  JOIN users u ON u.user_id = r.trainee_id
  WHERE r.trainer_id = ?
    AND r.status = 'approved'
  ORDER BY r.created_at DESC
");
$stmt->bind_param("i", $trainer_id);
$stmt->execute();
$reviews = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
$stmt->close();

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="lr-page-wrapper">
<div class="container lr-main-container py-4">

<div class="row mb-4">
  <div class="col-md-8">
    <div class="lr-section-title mb-1">Feedback</div>
    <h1 class="lr-section-heading mb-1">My Reviews</h1>
  </div>
</div>

<?php if ($err): ?>
  <div class="alert alert-danger"><?= htmlspecialchars($err) ?></div>
<?php endif; ?>

<?php if ($msg): ?>
  <div class="alert alert-success"><?= htmlspecialchars($msg) ?></div>
<?php endif; ?>

<?php if (!$reviews): ?>
  <div class="alert alert-info">No reviews yet.</div>
<?php else: ?>

<?php foreach ($reviews as $r): ?>
<div class="lr-card mb-3">
  <div class="lr-card-body">

    <div class="d-flex justify-content-between mb-2">
      <div>
        <strong><?= htmlspecialchars($r['trainee_name']) ?></strong>
      </div>
      <div>
        ⭐ <?= (int)$r['rating'] ?>
      </div>
    </div>

    <div class="lr-stat-subtext mb-2">
      <?= nl2br(htmlspecialchars($r['review_text'])) ?>
    </div>

    <div class="small text-secondary mb-2">
      <?= date("M d, Y", strtotime($r['created_at'])) ?>
    </div>

    <!-- FLAG FORM -->
    <form method="post" class="border-top pt-2 mt-2">
      <input type="hidden" name="review_id" value="<?= (int)$r['review_id'] ?>">
      <input type="hidden" name="flag_review" value="1">

      <div class="row g-2">
        <div class="col-md-4">
          <select name="reason" class="form-select form-select-sm" required>
            <option value="">Flag reason</option>
            <option value="abusive">Abusive language</option>
            <option value="spam">Spam</option>
            <option value="false_claim">False claims</option>
          </select>
        </div>
        <div class="col-md-6">
          <input type="text" name="details"
                 class="form-control form-control-sm"
                 placeholder="Optional details">
        </div>
        <div class="col-md-2 d-grid">
          <button class="btn btn-outline-warning btn-sm">Flag</button>
        </div>
      </div>
    </form>

  </div>
</div>
<?php endforeach; ?>

<?php endif; ?>

</div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>
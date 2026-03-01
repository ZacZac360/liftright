<?php
// liftright/web/admin/reviews.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['admin']);
$page_title = "Review Moderation";

$err = '';
$msg = '';

/* =========================================================
   HANDLE ACTIONS
========================================================= */

if ($_SERVER['REQUEST_METHOD'] === 'POST') {

  $action = $_POST['action'] ?? '';

  if ($action === 'delete_review') {

    $review_id = (int)($_POST['review_id'] ?? 0);

    $stmt = $mysqli->prepare("
      DELETE FROM trainer_reviews WHERE review_id=?
    ");
    $stmt->bind_param("i", $review_id);
    $stmt->execute();
    $stmt->close();

    $msg = "Review removed.";
  }

  if ($action === 'resolve_flag') {

    $flag_id = (int)($_POST['flag_id'] ?? 0);

    $stmt = $mysqli->prepare("
      UPDATE trainer_review_flags
      SET status='resolved', resolved_at=NOW()
      WHERE flag_id=?
    ");
    $stmt->bind_param("i", $flag_id);
    $stmt->execute();
    $stmt->close();

    $msg = "Flag resolved.";
  }
}

/* =========================================================
   LOAD FLAGGED REVIEWS FIRST
========================================================= */

$flags = $mysqli->query("
  SELECT f.flag_id, f.reason, f.details, f.created_at,
         r.review_id, r.review_text, r.rating,
         t.full_name AS trainer_name,
         u.full_name AS trainee_name
  FROM trainer_review_flags f
  JOIN trainer_reviews r ON r.review_id=f.review_id
  JOIN users t ON t.user_id=r.trainer_id
  JOIN users u ON u.user_id=r.trainee_id
  WHERE f.status='pending'
  ORDER BY f.created_at DESC
")->fetch_all(MYSQLI_ASSOC);

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="lr-page-wrapper">
<div class="container lr-main-container py-4">

<h1 class="lr-section-heading mb-4">Flagged Reviews</h1>

<?php if ($msg): ?>
<div class="alert alert-success"><?= htmlspecialchars($msg) ?></div>
<?php endif; ?>

<?php if (!$flags): ?>
<div class="alert alert-info">No flagged reviews.</div>
<?php else: ?>

<?php foreach ($flags as $f): ?>
<div class="lr-card mb-3">
<div class="lr-card-body">

<div class="mb-2">
<strong>Trainer:</strong> <?= htmlspecialchars($f['trainer_name']) ?><br>
<strong>Trainee:</strong> <?= htmlspecialchars($f['trainee_name']) ?><br>
⭐ <?= (int)$f['rating'] ?>
</div>

<div class="lr-stat-subtext mb-2">
<?= nl2br(htmlspecialchars($f['review_text'])) ?>
</div>

<div class="small text-danger mb-2">
Flag reason: <?= htmlspecialchars($f['reason']) ?>
<?php if ($f['details']): ?>
<br>Details: <?= htmlspecialchars($f['details']) ?>
<?php endif; ?>
</div>

<div class="d-flex gap-2">

<form method="post">
<input type="hidden" name="review_id" value="<?= (int)$f['review_id'] ?>">
<input type="hidden" name="action" value="delete_review">
<button class="btn btn-outline-danger btn-sm">
Delete Review
</button>
</form>

<form method="post">
<input type="hidden" name="flag_id" value="<?= (int)$f['flag_id'] ?>">
<input type="hidden" name="action" value="resolve_flag">
<button class="btn btn-outline-light btn-sm">
Resolve Flag
</button>
</form>

</div>

</div>
</div>
<?php endforeach; ?>

<?php endif; ?>

</div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>
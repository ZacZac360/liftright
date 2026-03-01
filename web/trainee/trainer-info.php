<?php
// liftright/web/trainee/trainer-info.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['user']);
$page_title = "Trainer Info";

$trainee_id = (int)($_SESSION['user_id'] ?? 0);
$err = '';
$msg = '';

/* =========================================================
   FIND CURRENT ASSIGNED TRAINER (via trainer_invites)
========================================================= */

$stmt = $mysqli->prepare("
  SELECT trainer_id
  FROM trainer_invites
  WHERE trainee_id = ?
    AND status = 'accepted'
  ORDER BY created_at DESC
  LIMIT 1
");
$stmt->bind_param("i", $trainee_id);
$stmt->execute();
$stmt->bind_result($trainer_id);
$stmt->fetch();
$stmt->close();

$trainer_id = (int)($trainer_id ?? 0);

$trainer = null;
$my_review = null;

/* =========================================================
   LOAD TRAINER PROFILE + SUMMARY
========================================================= */

if ($trainer_id > 0) {

  $stmt = $mysqli->prepare("
    SELECT u.user_id, u.full_name, u.profile_photo,
           u.qualification, u.years_experience,
           u.bio,
           COALESCE(s.avg_rating,0) AS avg_rating,
           COALESCE(s.review_count,0) AS review_count
    FROM users u
    LEFT JOIN trainer_rating_summary s ON s.trainer_id = u.user_id
    WHERE u.user_id = ?
    LIMIT 1
  ");
  $stmt->bind_param("i", $trainer_id);
  $stmt->execute();
  $trainer = $stmt->get_result()->fetch_assoc();
  $stmt->close();

  /* ---------------------------------------------------------
     LOAD MY REVIEW (if exists)
  --------------------------------------------------------- */

  $stmt = $mysqli->prepare("
    SELECT review_id, rating, review_text
    FROM trainer_reviews
    WHERE trainer_id=? AND trainee_id=?
    LIMIT 1
  ");
  $stmt->bind_param("ii", $trainer_id, $trainee_id);
  $stmt->execute();
  $my_review = $stmt->get_result()->fetch_assoc();
  $stmt->close();
}

/* =========================================================
   HANDLE REVIEW SUBMIT (CREATE OR UPDATE)
========================================================= */

if ($_SERVER['REQUEST_METHOD'] === 'POST' && $trainer_id > 0) {

  $rating = (int)($_POST['rating'] ?? 0);
  $review_text = trim($_POST['review_text'] ?? '');

  if ($rating < 1 || $rating > 5) {
    $err = "Rating must be between 1 and 5.";
  } else {

    $stmt = $mysqli->prepare("
      INSERT INTO trainer_reviews (trainer_id, trainee_id, rating, review_text, status)
      VALUES (?, ?, ?, ?, 'approved')
      ON DUPLICATE KEY UPDATE
        rating = VALUES(rating),
        review_text = VALUES(review_text),
        status = 'approved',
        updated_at = NOW()
    ");
    $stmt->bind_param("iiis", $trainer_id, $trainee_id, $rating, $review_text);
    $stmt->execute();
    $stmt->close();

    $msg = "Your review has been saved.";

    header("Location: trainer-info.php");
    exit;
  }
}

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="lr-page-wrapper">
<div class="container lr-main-container py-4">

<div class="row mb-4">
  <div class="col-md-8">
    <div class="lr-section-title mb-1">Trainer Profile</div>
    <h1 class="lr-section-heading mb-1">Trainer Information</h1>
    <p class="lr-stat-subtext mb-0">
      View your assigned trainer and leave feedback.
    </p>
  </div>
</div>

<?php if (!$trainer): ?>

<div class="alert alert-warning">
  You are not currently assigned to a trainer.
</div>

<?php else: ?>

<!-- TRAINER CARD -->
<div class="lr-card mb-4">
  <div class="lr-card-body">

    <div class="d-flex gap-3 align-items-center mb-3">

      <div class="avatar-circle" style="width:80px;height:80px;">
        <?php if (!empty($trainer['profile_photo'])): ?>
          <img src="<?= $BASE_URL.'/'.ltrim($trainer['profile_photo'],'/') ?>"
               style="width:100%;height:100%;object-fit:cover;">
        <?php else: ?>
          <?= strtoupper(substr($trainer['full_name'],0,1)) ?>
        <?php endif; ?>
      </div>

      <div>
        <div class="fw-semibold fs-5"><?= htmlspecialchars($trainer['full_name']) ?></div>
        <div class="lr-stat-subtext">
          <?= htmlspecialchars($trainer['qualification'] ?? 'Trainer') ?>
        </div>
        <div class="small">
          <?= (int)$trainer['years_experience'] ?> yrs experience
        </div>
        <div class="small">
          ⭐ <?= number_format($trainer['avg_rating'],1) ?>
          (<?= (int)$trainer['review_count'] ?> reviews)
        </div>
      </div>

    </div>

    <div class="lr-stat-subtext">
      <?= nl2br(htmlspecialchars($trainer['bio'] ?? '')) ?>
    </div>

  </div>
</div>

<!-- REVIEW FORM -->
<div class="lr-card">
  <div class="lr-card-header">
    <div class="lr-section-heading mb-0">
      <?= $my_review ? "Edit Your Review" : "Leave a Review" ?>
    </div>
  </div>

  <div class="lr-card-body">

    <?php if ($err): ?>
      <div class="alert alert-danger"><?= htmlspecialchars($err) ?></div>
    <?php endif; ?>

    <?php if ($msg): ?>
      <div class="alert alert-success"><?= htmlspecialchars($msg) ?></div>
    <?php endif; ?>

    <form method="post">

      <div class="mb-3">
        <label class="form-label">Rating</label>
        <select name="rating" class="form-select" required>
          <option value="">Select rating</option>
          <?php for ($i=1;$i<=5;$i++): ?>
            <option value="<?= $i ?>"
              <?= ($my_review && (int)$my_review['rating']===$i) ? 'selected':'' ?>>
              <?= $i ?> ⭐
            </option>
          <?php endfor; ?>
        </select>
      </div>

      <div class="mb-3">
        <label class="form-label">Review</label>
        <textarea name="review_text"
                  class="form-control"
                  rows="4"
                  placeholder="Share your experience..."><?= htmlspecialchars($my_review['review_text'] ?? '') ?></textarea>
      </div>

      <button class="btn btn-primary">
        <?= $my_review ? "Update Review" : "Submit Review" ?>
      </button>

    </form>

  </div>
</div>

<?php endif; ?>

</div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>
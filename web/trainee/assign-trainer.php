<?php
// liftright/web/trainee/assign-trainer.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';
require_once __DIR__ . '/../includes/profile_change_helpers.php';

require_role(['user']);
$page_title = "Assign Trainer";

$trainee_id = (int)$_SESSION['user_id'];
$err = '';
$msg = '';

/* =========================================================
   DETECT CURRENT STATE
========================================================= */

$stmt = $mysqli->prepare("
  SELECT *
  FROM trainer_invites
  WHERE trainee_id = ?
    AND status IN ('pending','accepted','unlink_requested')
  ORDER BY created_at DESC
  LIMIT 1
");
$stmt->bind_param("i", $trainee_id);
$stmt->execute();
$current = $stmt->get_result()->fetch_assoc();
$stmt->close();

$current_status = $current['status'] ?? null;
$current_trainer_id = (int)($current['trainer_id'] ?? 0);

$assigned_trainer = null;

if ($current_status === 'accepted' && $current_trainer_id > 0) {

  $stmt = $mysqli->prepare("
    SELECT u.user_id, u.full_name, u.profile_photo,
           u.qualification, u.years_experience,
           u.bio,
           COALESCE(r.avg_rating,0) AS avg_rating,
           COALESCE(r.review_count,0) AS review_count
    FROM users u
    LEFT JOIN trainer_rating_summary r ON r.trainer_id = u.user_id
    WHERE u.user_id = ?
    LIMIT 1
  ");
  $stmt->bind_param("i", $current_trainer_id);
  $stmt->execute();
  $assigned_trainer = $stmt->get_result()->fetch_assoc();
  $stmt->close();
}

/* =========================================================
   HANDLE ACTIONS
========================================================= */

if ($_SERVER['REQUEST_METHOD'] === 'POST') {

  // Cancel pending
  if (isset($_POST['cancel_invite']) && $current_status === 'pending') {

    $stmt = $mysqli->prepare("
      UPDATE trainer_invites
      SET status='cancelled', responded_at=NOW()
      WHERE invite_id=? AND trainee_id=?
    ");
    $stmt->bind_param("ii", $current['invite_id'], $trainee_id);
    $stmt->execute();
    $stmt->close();

    header("Location: assign-trainer.php");
    exit;
  }

  // Request unlink
  if (isset($_POST['request_unlink']) && $current_status === 'accepted') {

    $stmt = $mysqli->prepare("
      UPDATE trainer_invites
      SET status='unlink_requested'
      WHERE invite_id=? AND trainee_id=?
    ");
    $stmt->bind_param("ii", $current['invite_id'], $trainee_id);
    $stmt->execute();
    $stmt->close();

    $traineeName = (string)($_SESSION['full_name'] ?? ("Trainee #{$trainee_id}"));
    $trainerName = $assigned_trainer ? (string)$assigned_trainer['full_name'] : ("Trainer #{$current_trainer_id}");

    notify_all_admins(
      $mysqli,
      "Unlink requested: {$traineeName} (#{$trainee_id}) from {$trainerName} (#{$current_trainer_id}).",
      null,
      $trainee_id
    );

    header("Location: assign-trainer.php");
    exit;
  }

  // Send invite
  if (isset($_POST['send_invite'])) {

    if ($current_status) {
      $err = "You already have an active or pending trainer.";
    } else {

      $trainer_id = (int)($_POST['trainer_id'] ?? 0);

      if ($trainer_id > 0) {

        $token = bin2hex(random_bytes(32));

        $stmt = $mysqli->prepare("
          INSERT INTO trainer_invites
          (trainee_id, trainer_id, status, token, expires_at)
          VALUES (?, ?, 'pending', ?, DATE_ADD(NOW(), INTERVAL 7 DAY))
        ");
        $stmt->bind_param("iis", $trainee_id, $trainer_id, $token);
        $stmt->execute();
        $stmt->close();

        // PRG pattern: redirect so the top "current state" query runs fresh
        header("Location: assign-trainer.php?sent=1");
        exit;
      }
    }
  }
}

/* =========================================================
   FILTERS
========================================================= */

$q = trim($_GET['q'] ?? '');
$gender = trim($_GET['gender'] ?? '');
$exp = trim($_GET['exp'] ?? '');
$rating = trim($_GET['rating'] ?? '');
$page = max(1, (int)($_GET['page'] ?? 1));
$limit = 5;
$offset = ($page - 1) * $limit;

$where = "u.role='trainer'
          AND u.account_status='approved'
          AND u.accepting_trainees = 1";
$params = [];
$types = "";

if ($q !== '') {
  $where .= " AND (u.full_name LIKE CONCAT('%', ?, '%')
                OR u.qualification LIKE CONCAT('%', ?, '%')
                OR u.specializations LIKE CONCAT('%', ?, '%'))";
  $types .= "sss";
  $params[] = $q; $params[] = $q; $params[] = $q;
}

if ($gender !== '') {
  $where .= " AND u.gender=?";
  $types .= "s";
  $params[] = $gender;
}

if ($rating !== '') {
  $where .= " AND COALESCE(r.avg_rating,0) >= ?";
  $types .= "d";
  $params[] = (float)$rating;
}

/* =========================================================
   COUNT TOTAL (for pagination)
========================================================= */

$count_sql = "
  SELECT COUNT(*)
  FROM users u
  LEFT JOIN trainer_rating_summary r ON r.trainer_id=u.user_id
  WHERE $where
";
$stmt = $mysqli->prepare($count_sql);
if ($types !== "") $stmt->bind_param($types, ...$params);
$stmt->execute();
$stmt->bind_result($total_rows);
$stmt->fetch();
$stmt->close();

$total_pages = max(1, ceil($total_rows / $limit));

/* =========================================================
   LOAD TRAINERS
========================================================= */

$sql = "
  SELECT u.user_id, u.full_name, u.profile_photo,
         u.qualification, u.years_experience,
         u.specializations, u.bio,
         COALESCE(r.avg_rating,0) AS avg_rating,
         COALESCE(r.review_count,0) AS review_count
  FROM users u
  LEFT JOIN trainer_rating_summary r ON r.trainer_id=u.user_id
  WHERE $where
  ORDER BY avg_rating DESC, review_count DESC, u.years_experience DESC
  LIMIT $limit OFFSET $offset
";

$stmt = $mysqli->prepare($sql);
if ($types !== "") $stmt->bind_param($types, ...$params);
$stmt->execute();
$trainers = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
$stmt->close();

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="lr-page-wrapper">
<div class="container lr-main-container py-4">

<div class="row mb-4 align-items-center">
  <div class="col-md-8">
    <div class="lr-section-title mb-1">Coach Link</div>
    <h1 class="lr-section-heading mb-1">Trainer Directory</h1>
    <p class="lr-stat-subtext mb-0">
      Discover trainers by experience, specialization, and rating.
    </p>
  </div>
</div>

<?php if (isset($_GET['sent'])): ?>
  <div class="alert alert-success">
    Trainer request sent. Awaiting approval.
  </div>
<?php endif; ?>

<?php if (!empty($err)): ?>
  <div class="alert alert-danger">
    <?= h($err) ?>
  </div>
<?php endif; ?>

<?php if ($current_status === 'accepted' && $assigned_trainer): ?>

<div class="lr-card mb-4">
  <div class="lr-card-header d-flex justify-content-between align-items-center">
    <div>
      <div class="lr-section-title mb-1">Trainer Link</div>
      <div class="lr-section-heading mb-0">Currently Assigned</div>
    </div>
    <span class="lr-badge lr-badge-good">Active</span>
  </div>

  <div class="lr-card-body">

    <div class="d-flex gap-3 align-items-center mb-3">

      <div class="avatar-circle" style="width:80px;height:80px;">
        <?php if ($assigned_trainer['profile_photo']): ?>
          <img src="<?= $BASE_URL.'/'.ltrim($assigned_trainer['profile_photo'],'/') ?>"
               style="width:100%;height:100%;object-fit:cover;">
        <?php else: ?>
          <?= strtoupper(substr($assigned_trainer['full_name'],0,1)) ?>
        <?php endif; ?>
      </div>

      <div>
        <div class="fw-semibold fs-5"><?= h($assigned_trainer['full_name']) ?></div>
        <div class="lr-stat-subtext">
          <?= h($assigned_trainer['qualification'] ?? 'Trainer') ?>
        </div>
        <div class="small">
          <?= (int)$assigned_trainer['years_experience'] ?> yrs experience
        </div>
        <div class="small">
          ⭐ <?= number_format($assigned_trainer['avg_rating'],1) ?>
          (<?= (int)$assigned_trainer['review_count'] ?> reviews)
        </div>
      </div>

    </div>

    <div class="lr-stat-subtext mb-3">
      <?= h(substr($assigned_trainer['bio'] ?? '',0,200)) ?>
    </div>

    <form method="post">
      <button class="btn btn-outline-light btn-sm" name="request_unlink">
        Request Unlink
      </button>
    </form>

  </div>
</div>

<?php elseif ($current_status === 'pending'): ?>
<div class="alert alert-warning">
  <strong>Pending Trainer Approval.</strong>
  <form method="post" class="mt-2">
    <button class="btn btn-sm btn-outline-light" name="cancel_invite">
      Cancel Request
    </button>
  </form>
</div>
<?php elseif ($current_status === 'unlink_requested'): ?>
<div class="alert alert-warning">
  <strong>Unlink Request Submitted.</strong> Awaiting admin decision.
</div>
<?php endif; ?>

<div class="lr-card mb-4">
  <div class="lr-card-body">
    <form class="row g-3">

      <div class="col-md-4">
        <input class="form-control" name="q"
               placeholder="Search name, qualification, specialization"
               value="<?= h($q) ?>">
      </div>

      <div class="col-md-2">
        <select class="form-select" name="gender">
          <option value="">Gender</option>
          <option value="male">Male</option>
          <option value="female">Female</option>
          <option value="other">Other</option>
        </select>
      </div>

      <div class="col-md-2">
        <select class="form-select" name="rating">
          <option value="">Min Rating</option>
          <option value="3">3+</option>
          <option value="4">4+</option>
          <option value="4.5">4.5+</option>
        </select>
      </div>

      <div class="col-md-2">
        <button class="btn btn-primary w-100">Apply</button>
      </div>

    </form>
  </div>
</div>

<div class="row g-4">

<?php foreach ($trainers as $t): ?>
<div class="col-md-6">

<div class="lr-card h-100">
<div class="lr-card-body">

<div class="d-flex gap-3 align-items-center mb-3">

<div class="avatar-circle" style="width:72px;height:72px;">
<?php if ($t['profile_photo']): ?>
<img src="<?= $BASE_URL.'/'.ltrim($t['profile_photo'],'/') ?>"
     style="width:100%;height:100%;object-fit:cover;">
<?php else: ?>
<?= strtoupper(substr($t['full_name'],0,1)) ?>
<?php endif; ?>
</div>

<div>
<div class="fw-semibold"><?= h($t['full_name']) ?></div>
<div class="lr-stat-subtext"><?= h($t['qualification']) ?></div>
<div class="small"><?= (int)$t['years_experience'] ?> yrs exp</div>
<div class="small">⭐ <?= number_format($t['avg_rating'],1) ?>
 (<?= (int)$t['review_count'] ?> reviews)</div>
</div>

</div>

<div class="lr-stat-subtext mb-3">
<?= h(substr($t['bio'] ?? '',0,140)) ?>
</div>

<?php if (!$current_status): ?>
<form method="post">
<input type="hidden" name="send_invite" value="1">
<input type="hidden" name="trainer_id" value="<?= $t['user_id'] ?>">
<button class="btn btn-primary btn-sm">Request Trainer</button>
</form>
<?php else: ?>
<button class="btn btn-outline-light btn-sm" disabled>Unavailable</button>
<?php endif; ?>

</div>
</div>

</div>
<?php endforeach; ?>

</div>

<!-- Pagination -->
<?php if ($total_pages > 1): ?>
<div class="mt-4 text-center">
<?php for ($i=1;$i<=$total_pages;$i++): ?>
<a class="btn btn-sm <?= $i==$page?'btn-primary':'btn-outline-light' ?>"
   href="?<?= http_build_query(array_merge($_GET,['page'=>$i])) ?>">
  <?= $i ?>
</a>
<?php endfor; ?>
</div>
<?php endif; ?>

</div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>
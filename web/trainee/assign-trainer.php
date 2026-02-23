<?php
// liftright/web/trainee/assign-trainer.php
session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['user']);
$page_title = "Assign Trainer";

$trainee_id = (int)$_SESSION['user_id'];
$err = '';
$msg = '';

function rand_token(int $bytes = 32): string {
  return bin2hex(random_bytes($bytes)); // 64 hex chars when $bytes=32
}

// Load trainee + assigned trainer (if any)
$stmt = $mysqli->prepare("
  SELECT u.user_id, u.full_name, u.trainer_id,
         t.full_name AS trainer_name, t.email AS trainer_email
  FROM users u
  LEFT JOIN users t ON t.user_id = u.trainer_id
  WHERE u.user_id = ?
  LIMIT 1
");
$stmt->bind_param("i", $trainee_id);
$stmt->execute();
$me = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$me) {
  header("Location: {$BASE_URL}/trainee/dashboard.php");
  exit;
}

$assigned_trainer_id = (int)($me['trainer_id'] ?? 0);

// Load latest invite (for display)
$latest_invite = null;
$stmt = $mysqli->prepare("
  SELECT invite_id, trainee_id, trainer_id, status, expires_at, created_at, responded_at
  FROM trainer_invites
  WHERE trainee_id = ?
  ORDER BY created_at DESC
  LIMIT 1
");
$stmt->bind_param("i", $trainee_id);
$stmt->execute();
$latest_invite = $stmt->get_result()->fetch_assoc();
$stmt->close();

// Handle cancel pending invite
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['cancel_invite'])) {
  $invite_id = (int)($_POST['invite_id'] ?? 0);

  if ($invite_id <= 0) {
    $err = "Invalid invite.";
  } else {
    $stmt = $mysqli->prepare("
      UPDATE trainer_invites
      SET status = 'cancelled', responded_at = NOW()
      WHERE invite_id = ? AND trainee_id = ? AND status = 'pending'
    ");
    $stmt->bind_param("ii", $invite_id, $trainee_id);
    $stmt->execute();
    $affected = $stmt->affected_rows;
    $stmt->close();

    if ($affected > 0) {
      $msg = "Invite cancelled.";
    } else {
      $err = "Unable to cancel invite (maybe already processed).";
    }
  }
}

// Handle send invite
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['send_invite'])) {
  if ($assigned_trainer_id > 0) {
    $err = "You already have an assigned trainer.";
  } else {
    $trainer_email = trim((string)($_POST['trainer_email'] ?? ''));
    $trainer_id_in = (int)($_POST['trainer_id'] ?? 0);

    // find trainer
    $trainer = null;
    if ($trainer_id_in > 0) {
      $stmt = $mysqli->prepare("SELECT user_id, full_name FROM users WHERE user_id = ? AND role='trainer' LIMIT 1");
      $stmt->bind_param("i", $trainer_id_in);
      $stmt->execute();
      $trainer = $stmt->get_result()->fetch_assoc();
      $stmt->close();
    } elseif ($trainer_email !== '') {
      $stmt = $mysqli->prepare("SELECT user_id, full_name FROM users WHERE email = ? AND role='trainer' LIMIT 1");
      $stmt->bind_param("s", $trainer_email);
      $stmt->execute();
      $trainer = $stmt->get_result()->fetch_assoc();
      $stmt->close();
    }

    if (!$trainer) {
      $err = "Trainer not found. Check the email or ID.";
    } else {
      $trainer_id = (int)$trainer['user_id'];

      // prevent duplicate pending invite to same trainer
      $stmt = $mysqli->prepare("
        SELECT invite_id
        FROM trainer_invites
        WHERE trainee_id = ? AND trainer_id = ? AND status = 'pending'
        LIMIT 1
      ");
      $stmt->bind_param("ii", $trainee_id, $trainer_id);
      $stmt->execute();
      $dup = $stmt->get_result()->fetch_assoc();
      $stmt->close();

      if ($dup) {
        $err = "You already have a pending invite for this trainer.";
      } else {
        $token = rand_token(32);

        $stmt = $mysqli->prepare("
          INSERT INTO trainer_invites (trainee_id, trainer_id, status, token, expires_at)
          VALUES (?, ?, 'pending', ?, DATE_ADD(NOW(), INTERVAL 7 DAY))
        ");
        $stmt->bind_param("iis", $trainee_id, $trainer_id, $token);
        $stmt->execute();
        $stmt->close();

        // notify trainer
        $notif_msg = "New trainer request from: " . (string)$me['full_name'] . " (Trainee ID: {$trainee_id})";
        $stmt = $mysqli->prepare("
          INSERT INTO notifications (user_id, notif_type, message, from_user_id)
          VALUES (?, 'assignment', ?, ?)
        ");
        $stmt->bind_param("isi", $trainer_id, $notif_msg, $trainee_id);
        $stmt->execute();
        $stmt->close();

        $msg = "Invite sent. Waiting for trainer approval.";
      }
    }
  }
}

// Reload latest invite after actions
$stmt = $mysqli->prepare("
  SELECT i.invite_id, i.trainee_id, i.trainer_id, i.status, i.expires_at, i.created_at, i.responded_at,
         u.full_name AS trainer_name, u.email AS trainer_email
  FROM trainer_invites i
  JOIN users u ON u.user_id = i.trainer_id
  WHERE i.trainee_id = ?
  ORDER BY i.created_at DESC
  LIMIT 1
");
$stmt->bind_param("i", $trainee_id);
$stmt->execute();
$latest_invite = $stmt->get_result()->fetch_assoc();
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
        <h1 class="lr-section-heading mb-1">Assign Trainer</h1>
        <p class="lr-stat-subtext mb-0">Invite a trainer to review your sessions and provide written feedback.</p>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0">
        <a class="btn btn-outline-light" href="<?= $BASE_URL ?>/trainee/dashboard.php">← Back</a>
      </div>
    </div>

    <?php if ($err !== ''): ?>
      <div class="alert alert-danger"><?= h($err) ?></div>
    <?php elseif ($msg !== ''): ?>
      <div class="alert alert-success"><?= h($msg) ?></div>
    <?php endif; ?>

    <div class="row g-4">
      <div class="col-lg-5">
        <div class="lr-card">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">Status</div>
            <div class="lr-section-heading mb-0">Current trainer</div>
          </div>
          <div class="lr-card-body">
            <?php if ($assigned_trainer_id > 0): ?>
              <div class="d-flex justify-content-between align-items-center mb-2">
                <div>
                  <div class="fw-semibold"><?= h((string)$me['trainer_name']) ?></div>
                  <div class="lr-stat-subtext mb-0"><?= h((string)$me['trainer_email']) ?></div>
                </div>
                <span class="lr-badge lr-badge-good">Assigned</span>
              </div>
              <div class="lr-stat-subtext">You can now receive trainer reviews on your sessions.</div>
            <?php else: ?>
              <div class="d-flex justify-content-between align-items-center mb-2">
                <div class="fw-semibold">No trainer assigned</div>
                <span class="lr-badge lr-badge-warning">Unassigned</span>
              </div>
              <div class="lr-stat-subtext">Send an invite to link to a trainer.</div>
            <?php endif; ?>

            <?php if ($latest_invite): ?>
              <hr style="border-color: rgba(148,163,184,0.14);">
              <div class="lr-section-title mb-2">Latest invite</div>
              <div class="d-flex justify-content-between align-items-center">
                <div class="text-capitalize fw-semibold"><?= h((string)$latest_invite['status']) ?></div>
                <div class="lr-stat-subtext mb-0"><?= h(date("M d, Y", strtotime((string)$latest_invite['created_at']))) ?></div>
              </div>
              <div class="lr-stat-subtext mt-1">
                Trainer: <?= h((string)$latest_invite['trainer_name']) ?>
                <span class="text-secondary" style="opacity:.85;">(<?= h((string)$latest_invite['trainer_email']) ?>)</span>
              </div>
              <?php if (!empty($latest_invite['expires_at'])): ?>
                <div class="lr-stat-subtext mb-0">Expires: <?= h(date("M d, Y • g:i A", strtotime((string)$latest_invite['expires_at']))) ?></div>
              <?php endif; ?>

              <?php if ((string)$latest_invite['status'] === 'pending' && $assigned_trainer_id === 0): ?>
                <form method="post" class="mt-3">
                  <input type="hidden" name="cancel_invite" value="1">
                  <input type="hidden" name="invite_id" value="<?= (int)$latest_invite['invite_id'] ?>">
                  <button class="btn btn-sm btn-outline-light">
                    <i class="fa-solid fa-ban me-2"></i>Cancel invite
                  </button>
                </form>
              <?php endif; ?>
            <?php endif; ?>
          </div>
        </div>
      </div>

      <div class="col-lg-7">
        <div class="lr-card">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">Invite</div>
            <div class="lr-section-heading mb-0">Request trainer approval</div>
          </div>
          <div class="lr-card-body">
            <?php if ($assigned_trainer_id > 0): ?>
              <div class="lr-stat-subtext">Already assigned. (Change-trainer flow can be added later.)</div>
            <?php else: ?>
              <form method="post" class="row g-3">
                <input type="hidden" name="send_invite" value="1">

                <div class="col-md-6">
                  <label class="form-label lr-stat-label">Trainer email (recommended)</label>
                  <input class="form-control" name="trainer_email" type="email" placeholder="trainer@example.com">
                </div>

                <div class="col-md-6">
                  <label class="form-label lr-stat-label">Or trainer ID</label>
                  <input class="form-control" name="trainer_id" type="number" min="1" placeholder="e.g. 12">
                </div>

                <div class="col-12 d-grid d-md-flex justify-content-md-end">
                  <button class="btn btn-primary px-4">
                    <i class="fa-regular fa-paper-plane me-2"></i>Send Invite
                  </button>
                </div>

                <div class="col-12">
                  <div class="lr-stat-subtext">
                    Invite expires after 7 days. Trainer must accept to link accounts.
                  </div>
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
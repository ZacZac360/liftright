<?php
// liftright/web/coach/invitations.php
session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['trainer']);
$page_title = "Invitations";

$trainer_id = (int)$_SESSION['user_id'];
$err = '';
$msg = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $invite_id = (int)($_POST['invite_id'] ?? 0);
  $action = (string)($_POST['action'] ?? '');

  if ($invite_id <= 0 || !in_array($action, ['accept','decline'], true)) {
    $err = "Invalid action.";
  } else {
    // Load invite (must belong to trainer)
    $stmt = $mysqli->prepare("
      SELECT i.invite_id, i.trainee_id, i.trainer_id, i.status,
             u.full_name AS trainee_name
      FROM trainer_invites i
      JOIN users u ON u.user_id = i.trainee_id
      WHERE i.invite_id = ? AND i.trainer_id = ?
      LIMIT 1
    ");
    $stmt->bind_param("ii", $invite_id, $trainer_id);
    $stmt->execute();
    $inv = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$inv) {
      $err = "Invite not found.";
    } elseif ($inv['status'] !== 'pending') {
      $err = "Invite already processed.";
    } else {
      $trainee_id = (int)$inv['trainee_id'];

      // Make sure trainee is not already assigned (optional safety)
      $stmt = $mysqli->prepare("SELECT trainer_id FROM users WHERE user_id = ? AND role='user' LIMIT 1");
      $stmt->bind_param("i", $trainee_id);
      $stmt->execute();
      $trainee_row = $stmt->get_result()->fetch_assoc();
      $stmt->close();

      $already = (int)($trainee_row['trainer_id'] ?? 0);
      if ($already > 0 && $already !== $trainer_id) {
        $err = "This trainee is already assigned to another trainer.";
      } else {
        if ($action === 'accept') {
          // accept invite
          $stmt = $mysqli->prepare("
            UPDATE trainer_invites
            SET status='accepted', responded_at=NOW()
            WHERE invite_id = ? AND trainer_id = ? AND status='pending'
          ");
          $stmt->bind_param("ii", $invite_id, $trainer_id);
          $stmt->execute();
          $stmt->close();

          // assign trainer
          $stmt = $mysqli->prepare("
            UPDATE users
            SET trainer_id = ?
            WHERE user_id = ? AND role='user'
          ");
          $stmt->bind_param("ii", $trainer_id, $trainee_id);
          $stmt->execute();
          $stmt->close();

          // notify trainee
          $notif_msg = "Trainer accepted your request. You are now linked.";
          $stmt = $mysqli->prepare("
            INSERT INTO notifications (user_id, notif_type, message, from_user_id)
            VALUES (?, 'assignment', ?, ?)
          ");
          $stmt->bind_param("isi", $trainee_id, $notif_msg, $trainer_id);
          $stmt->execute();
          $stmt->close();

          $msg = "Accepted invite for trainee ID {$trainee_id}.";
        } else {
          // decline invite
          $stmt = $mysqli->prepare("
            UPDATE trainer_invites
            SET status='declined', responded_at=NOW()
            WHERE invite_id = ? AND trainer_id = ? AND status='pending'
          ");
          $stmt->bind_param("ii", $invite_id, $trainer_id);
          $stmt->execute();
          $stmt->close();

          // notify trainee
          $notif_msg = "Trainer declined your request. You may invite a different trainer.";
          $stmt = $mysqli->prepare("
            INSERT INTO notifications (user_id, notif_type, message, from_user_id)
            VALUES (?, 'assignment', ?, ?)
          ");
          $stmt->bind_param("isi", $trainee_id, $notif_msg, $trainer_id);
          $stmt->execute();
          $stmt->close();

          $msg = "Declined invite for trainee ID {$trainee_id}.";
        }
      }
    }
  }
}

// fetch pending invites
$invites = [];
$stmt = $mysqli->prepare("
  SELECT i.invite_id, i.trainee_id, u.full_name AS trainee_name,
         i.created_at, i.expires_at
  FROM trainer_invites i
  JOIN users u ON u.user_id = i.trainee_id
  WHERE i.trainer_id = ? AND i.status = 'pending'
  ORDER BY i.created_at DESC
  LIMIT 200
");
$stmt->bind_param("i", $trainer_id);
$stmt->execute();
$res = $stmt->get_result();
while ($r = $res->fetch_assoc()) $invites[] = $r;
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
        <h1 class="lr-section-heading mb-1">Invitations</h1>
        <p class="lr-stat-subtext mb-0">Approve trainee requests to link accounts for expert reviews.</p>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0">
        <a class="btn btn-outline-light" href="<?= $BASE_URL ?>/coach/dashboard.php">← Back</a>
      </div>
    </div>

    <?php if ($err !== ''): ?>
      <div class="alert alert-danger"><?= h($err) ?></div>
    <?php elseif ($msg !== ''): ?>
      <div class="alert alert-success"><?= h($msg) ?></div>
    <?php endif; ?>

    <div class="lr-card">
      <div class="lr-card-header">
        <div class="lr-section-title mb-1">Pending</div>
        <div class="lr-section-heading mb-0">Trainee requests</div>
      </div>

      <div class="lr-card-body p-0">
        <div class="table-responsive">
          <table class="table table-hover table-striped align-middle mb-0 table-lr-dark">
            <thead>
              <tr>
                <th>Date</th>
                <th>Trainee</th>
                <th>Expires</th>
                <th class="text-end">Action</th>
              </tr>
            </thead>
            <tbody>
              <?php if (count($invites) === 0): ?>
                <tr>
                  <td colspan="4" class="text-center py-4 lr-stat-subtext">No pending invites.</td>
                </tr>
              <?php else: ?>
                <?php foreach ($invites as $i): ?>
                  <tr>
                    <td><?= h(date("M d, Y • g:i A", strtotime((string)$i['created_at']))) ?></td>
                    <td><?= h((string)$i['trainee_name']) ?> <span class="lr-stat-subtext">(ID: <?= (int)$i['trainee_id'] ?>)</span></td>
                    <td><?= empty($i['expires_at']) ? '—' : h(date("M d, Y", strtotime((string)$i['expires_at']))) ?></td>
                    <td class="text-end">
                      <form method="post" class="d-inline">
                        <input type="hidden" name="invite_id" value="<?= (int)$i['invite_id'] ?>">
                        <input type="hidden" name="action" value="accept">
                        <button class="btn btn-sm btn-primary">Accept</button>
                      </form>
                      <form method="post" class="d-inline ms-2">
                        <input type="hidden" name="invite_id" value="<?= (int)$i['invite_id'] ?>">
                        <input type="hidden" name="action" value="decline">
                        <button class="btn btn-sm btn-outline-light">Decline</button>
                      </form>
                    </td>
                  </tr>
                <?php endforeach; ?>
              <?php endif; ?>
            </tbody>
          </table>
        </div>
      </div>
    </div>

  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>
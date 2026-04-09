<?php
session_start();
require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/auth.php';

require_role(['user','trainer','admin']);

$page_title = "Message";
$user_id = (int)$_SESSION['user_id'];
$message_id = isset($_GET['id']) ? (int)$_GET['id'] : 0;

if ($message_id <= 0) {
  header("Location: {$BASE_URL}/messages.php");
  exit;
}

// load message
$stmt = $mysqli->prepare("
  SELECT m.message_id, m.sender_id, u.full_name AS sender_name,
         m.subject, m.body, m.log_id, m.is_read, m.created_at
  FROM messages m
  JOIN users u ON u.user_id = m.sender_id
  WHERE m.message_id = ? AND m.recipient_id = ?
  LIMIT 1
");
$stmt->bind_param("ii", $message_id, $user_id);
$stmt->execute();
$msg = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$msg) {
  header("Location: {$BASE_URL}/messages.php");
  exit;
}

// mark read
if ((int)$msg['is_read'] === 0) {
  $stmt = $mysqli->prepare("UPDATE messages SET is_read = 1 WHERE message_id = ? AND recipient_id = ?");
  $stmt->bind_param("ii", $message_id, $user_id);
  $stmt->execute();
  $stmt->close();
  $msg['is_read'] = 1;
}

require __DIR__ . '/includes/head.php';
?>
<body>
<?php require __DIR__ . '/includes/navbar.php'; ?>

<div class="lr-page-wrapper">
  <div class="container lr-main-container py-4">

    <div class="row mb-4 align-items-center">
      <div class="col-md-8">
        <div class="lr-section-title mb-1">Message</div>
        <h1 class="lr-section-heading mb-1"><?= h((string)($msg['subject'] ?? 'No subject')) ?></h1>
        <p class="lr-stat-subtext mb-0">
          From <?= h((string)$msg['sender_name']) ?> • <?= h(date("M d, Y • g:i A", strtotime((string)$msg['created_at']))) ?>
        </p>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0 d-flex justify-content-md-end gap-2">
        <a class="btn btn-outline-light" href="<?= $BASE_URL ?>/messages.php">← Back</a>
        <a class="btn btn-primary" href="<?= $BASE_URL ?>/compose-message.php?reply_to=<?= (int)$msg['message_id'] ?>">
          Reply
        </a>
      </div>
    </div>

    <div class="lr-card">
      <div class="lr-card-body">
        <div class="lr-prewrap"><?= h((string)$msg['body']) ?></div>
      </div>
    </div>

  </div>
</div>

<?php require __DIR__ . '/includes/footer.php'; ?>
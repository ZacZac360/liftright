<?php
session_start();
require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/auth.php';

require_role(['user','trainer','admin']);

$page_title = "Messages";
$user_id = (int)$_SESSION['user_id'];
$role = (string)($_SESSION['role'] ?? 'user');

// mark all read (for recipient)
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['mark_all_read'])) {
  $stmt = $mysqli->prepare("UPDATE messages SET is_read = 1 WHERE recipient_id = ?");
  $stmt->bind_param("i", $user_id);
  $stmt->execute();
  $stmt->close();

  header("Location: {$BASE_URL}/messages.php");
  exit;
}

// fetch inbox
$messages = [];
$stmt = $mysqli->prepare("
  SELECT m.message_id, m.sender_id, u.full_name AS sender_name,
         m.subject, m.body, m.is_read, m.created_at
  FROM messages m
  JOIN users u ON u.user_id = m.sender_id
  WHERE m.recipient_id = ?
  ORDER BY m.created_at DESC
  LIMIT 200
");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$res = $stmt->get_result();
while ($row = $res->fetch_assoc()) $messages[] = $row;
$stmt->close();

require __DIR__ . '/includes/head.php';
?>
<body>
<?php require __DIR__ . '/includes/navbar.php'; ?>

<div class="lr-page-wrapper">
  <div class="container lr-main-container py-4">

    <div class="row mb-4 align-items-center">
      <div class="col-md-8">
        <div class="lr-section-title mb-1">Inbox</div>
        <h1 class="lr-section-heading mb-1">Messages</h1>
        <p class="lr-stat-subtext mb-0">Direct communication between trainee and trainer.</p>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0 d-flex justify-content-md-end gap-2">
        <a class="btn btn-primary" href="<?= $BASE_URL ?>/compose-message.php">
          <i class="fa-regular fa-pen-to-square me-2"></i>Compose
        </a>
        <form method="post" class="m-0">
          <button class="btn btn-outline-light" name="mark_all_read" value="1" type="submit">
            <i class="fa-regular fa-circle-check me-2"></i>Mark all read
          </button>
        </form>
      </div>
    </div>

    <div class="lr-card">
      <div class="lr-card-body p-0">
        <div class="table-responsive">
          <table class="table table-hover table-striped align-middle mb-0 table-lr-dark">
            <thead>
              <tr>
                <th style="width: 30%;">From</th>
                <th>Subject / Preview</th>
                <th style="width: 20%;">Date</th>
                <th style="width: 10%;" class="text-end"></th>
              </tr>
            </thead>
            <tbody>
              <?php if (count($messages) === 0): ?>
                <tr>
                  <td colspan="4" class="text-center py-4 lr-stat-subtext">No messages yet.</td>
                </tr>
              <?php else: ?>
                <?php foreach ($messages as $m): ?>
                  <?php
                    $isUnread = ((int)$m['is_read'] === 0);
                    $subject = trim((string)($m['subject'] ?? ''));
                    $preview = $subject !== '' ? $subject : mb_substr(trim((string)$m['body']), 0, 70) . (mb_strlen(trim((string)$m['body'])) > 70 ? '…' : '');
                  ?>
                  <tr>
                    <td>
                      <div class="d-flex align-items-center gap-2">
                        <?php if ($isUnread): ?>
                          <span class="lr-badge lr-badge-warning">Unread</span>
                        <?php else: ?>
                          <span class="lr-badge lr-badge-good">Read</span>
                        <?php endif; ?>
                        <span><?= h((string)$m['sender_name']) ?></span>
                      </div>
                    </td>
                    <td><?= h($preview) ?></td>
                    <td><?= h(date("M d, Y • g:i A", strtotime((string)$m['created_at']))) ?></td>
                    <td class="text-end">
                      <a class="btn btn-sm btn-outline-light"
                         href="<?= $BASE_URL ?>/message-view.php?id=<?= (int)$m['message_id'] ?>">
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
    </div>

  </div>
</div>

<?php require __DIR__ . '/includes/footer.php'; ?>
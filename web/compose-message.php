<?php
session_start();
require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/auth.php';

require_role(['user','trainer','admin']);

$page_title = "Compose Message";
$user_id = (int)$_SESSION['user_id'];
$role = (string)($_SESSION['role'] ?? 'user');

$to_id = 0;
$subject = '';
$body = '';
$errors = [];
$sent = false;

// Determine allowed recipients
$recipients = []; // array of [user_id, full_name]

if ($role === 'user') {
  // only assigned trainer
  $stmt = $mysqli->prepare("
    SELECT u2.user_id, u2.full_name
    FROM users u1
    JOIN users u2 ON u2.user_id = u1.trainer_id
    WHERE u1.user_id = ? AND u2.role = 'trainer'
    LIMIT 1
  ");
  $stmt->bind_param("i", $user_id);
  $stmt->execute();
  $r = $stmt->get_result()->fetch_assoc();
  $stmt->close();
  if ($r) $recipients[] = $r;
} elseif ($role === 'trainer') {
  // trainees assigned to this trainer
  $stmt = $mysqli->prepare("
    SELECT user_id, full_name
    FROM users
    WHERE role = 'user' AND trainer_id = ?
    ORDER BY full_name ASC
    LIMIT 200
  ");
  $stmt->bind_param("i", $user_id);
  $stmt->execute();
  $res = $stmt->get_result();
  while ($row = $res->fetch_assoc()) $recipients[] = $row;
  $stmt->close();
} else { // admin
  $stmt = $mysqli->prepare("
    SELECT user_id, full_name
    FROM users
    WHERE user_id <> ?
    ORDER BY role DESC, full_name ASC
    LIMIT 200
  ");
  $stmt->bind_param("i", $user_id);
  $stmt->execute();
  $res = $stmt->get_result();
  while ($row = $res->fetch_assoc()) $recipients[] = $row;
  $stmt->close();
}

$allowed_ids = array_map(fn($r) => (int)$r['user_id'], $recipients);

// handle reply prefills (simple)
if (isset($_GET['reply_to'])) {
  $reply_id = (int)$_GET['reply_to'];
  if ($reply_id > 0) {
    // load original message (must be recipient)
    $stmt = $mysqli->prepare("
      SELECT sender_id, subject
      FROM messages
      WHERE message_id = ? AND recipient_id = ?
      LIMIT 1
    ");
    $stmt->bind_param("ii", $reply_id, $user_id);
    $stmt->execute();
    $orig = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if ($orig) {
      $to_id = (int)$orig['sender_id'];
      $subject = 'Re: ' . (string)($orig['subject'] ?? '');
    }
  }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $to_id = (int)($_POST['to_id'] ?? 0);
  $subject = trim((string)($_POST['subject'] ?? ''));
  $body = trim((string)($_POST['body'] ?? ''));

  if ($to_id <= 0 || !in_array($to_id, $allowed_ids, true)) {
    $errors[] = "Invalid recipient.";
  }
  if ($body === '') {
    $errors[] = "Message body cannot be empty.";
  }
  if (mb_strlen($subject) > 120) {
    $errors[] = "Subject is too long (max 120).";
  }

  if (empty($errors)) {
    $stmt = $mysqli->prepare("
      INSERT INTO messages (sender_id, recipient_id, subject, body, is_read)
      VALUES (?, ?, ?, ?, 0)
    ");
    $stmt->bind_param("iiss", $user_id, $to_id, $subject, $body);
    $stmt->execute();
    $stmt->close();

    // notify recipient
    $notif_msg = ($subject !== '')
      ? "New message: {$subject}"
      : "New message received.";
    $stmt = $mysqli->prepare("
      INSERT INTO notifications (user_id, notif_type, message, from_user_id)
      VALUES (?, 'system', ?, ?)
    ");
    $stmt->bind_param("isi", $to_id, $notif_msg, $user_id);
    $stmt->execute();
    $stmt->close();

    header("Location: {$BASE_URL}/messages.php?sent=1");
    exit;
  }
}

require __DIR__ . '/includes/head.php';
?>
<body>
<?php require __DIR__ . '/includes/navbar.php'; ?>

<div class="lr-page-wrapper">
  <div class="container lr-main-container py-4">

    <div class="row mb-4 align-items-center">
      <div class="col-md-8">
        <div class="lr-section-title mb-1">Messages</div>
        <h1 class="lr-section-heading mb-1">Compose</h1>
        <p class="lr-stat-subtext mb-0">Send a message to your trainer/trainee.</p>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0">
        <a class="btn btn-outline-light" href="<?= $BASE_URL ?>/messages.php">← Back</a>
      </div>
    </div>

    <div class="lr-card">
      <div class="lr-card-body">

        <?php if (!empty($errors)): ?>
          <div class="alert alert-danger">
            <ul class="mb-0">
              <?php foreach ($errors as $e): ?><li><?= h($e) ?></li><?php endforeach; ?>
            </ul>
          </div>
        <?php endif; ?>

        <?php if (count($recipients) === 0): ?>
          <div class="lr-stat-subtext">
            No available recipients. (For trainees: you must be assigned to a trainer first.)
          </div>
        <?php else: ?>
          <form method="post" class="row g-3">
            <div class="col-md-6">
              <label class="form-label lr-stat-label">To</label>
              <select class="form-select" name="to_id" required>
                <option value="">Select recipient…</option>
                <?php foreach ($recipients as $r): ?>
                  <option value="<?= (int)$r['user_id'] ?>" <?= ((int)$to_id === (int)$r['user_id']) ? 'selected' : '' ?>>
                    <?= h((string)$r['full_name']) ?> (ID: <?= (int)$r['user_id'] ?>)
                  </option>
                <?php endforeach; ?>
              </select>
            </div>

            <div class="col-md-6">
              <label class="form-label lr-stat-label">Subject (optional)</label>
              <input class="form-control" name="subject" maxlength="120" value="<?= h($subject) ?>">
            </div>

            <div class="col-12">
              <label class="form-label lr-stat-label">Message</label>
              <textarea class="form-control" name="body" rows="6" required><?= h($body) ?></textarea>
            </div>

            <div class="col-12 d-grid d-md-flex justify-content-md-end">
              <button class="btn btn-primary px-4">
                <i class="fa-regular fa-paper-plane me-2"></i>Send
              </button>
            </div>
          </form>
        <?php endif; ?>

      </div>
    </div>

  </div>
</div>

<?php require __DIR__ . '/includes/footer.php'; ?>
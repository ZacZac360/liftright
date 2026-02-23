<?php
session_start();
require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/auth.php';

require_role(['user','trainer','admin']);

$page_title = "Notifications";
$user_id = (int)$_SESSION['user_id'];

// mark read (optional)
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['mark_all_read'])) {
  $stmt = $mysqli->prepare("UPDATE notifications SET is_read = 1 WHERE user_id = ?");
  $stmt->bind_param("i", $user_id);
  $stmt->execute();
  $stmt->close();

  header("Location: {$BASE_URL}/notifications.php");
  exit;
}

// fetch latest
$notifs = [];
$stmt = $mysqli->prepare("
  SELECT notif_id, notif_type, message, log_id, from_user_id, is_read, created_at
  FROM notifications
  WHERE user_id = ?
  ORDER BY created_at DESC
  LIMIT 100
");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$res = $stmt->get_result();
while ($n = $res->fetch_assoc()) $notifs[] = $n;
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
        <h1 class="lr-section-heading mb-1">Notifications</h1>
        <p class="lr-stat-subtext mb-0">Updates about assignments, reviews, and system events.</p>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0">
        <form method="post" class="d-inline">
          <button class="btn btn-outline-light" name="mark_all_read" value="1">
            <i class="fa-regular fa-circle-check me-2"></i>Mark all as read
          </button>
        </form>
      </div>
    </div>

    <div class="lr-card">
      <div class="lr-card-body">
        <?php if (count($notifs) === 0): ?>
          <div class="lr-stat-subtext">No notifications yet.</div>
        <?php else: ?>
          <div class="d-grid gap-2">
            <?php foreach ($notifs as $n): ?>
              <?php
                $unreadStyle = ((int)$n['is_read'] === 0)
                  ? "border:1px solid rgba(79,157,252,0.45); background: rgba(79,157,252,0.08);"
                  : "border:1px solid var(--lr-border); background: rgba(15,23,42,0.45);";
              ?>
              <div class="p-3 rounded-3" style="<?= $unreadStyle ?>">
                <div class="d-flex justify-content-between align-items-start gap-3">
                  <div>
                    <div class="lr-section-title mb-1 text-capitalize"><?= h((string)$n['notif_type']) ?></div>
                    <div><?= h((string)$n['message']) ?></div>
                    <div class="lr-stat-subtext mt-2 mb-0">
                      <?= h(date("M d, Y • g:i A", strtotime((string)$n['created_at']))) ?>
                    </div>
                  </div>

                  <?php if (!empty($n['log_id'])): ?>
                    <?php
                      // role-aware session view link
                      $log_id = (int)$n['log_id'];
                      $role = $_SESSION['role'] ?? 'user';
                      $href = ($role === 'trainer')
                        ? "{$BASE_URL}/coach/session-view.php?log_id={$log_id}"
                        : (($role === 'admin')
                          ? "{$BASE_URL}/admin/session-view.php?log_id={$log_id}" // optional later
                          : "{$BASE_URL}/trainee/session-view.php?log_id={$log_id}");
                    ?>
                    <a class="btn btn-sm btn-outline-light" href="<?= h($href) ?>">Open</a>
                  <?php endif; ?>
                </div>
              </div>
            <?php endforeach; ?>
          </div>
        <?php endif; ?>
      </div>
    </div>

  </div>
</div>

<?php require __DIR__ . '/includes/footer.php'; ?>
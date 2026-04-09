<?php
session_start();
require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/auth.php';

require_role(['user','trainer','admin']);

$page_title = "Notifications";
$user_id = (int)$_SESSION['user_id'];

// mark read
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['mark_all_read'])) {
  $stmt = $mysqli->prepare("UPDATE notifications SET is_read = 1 WHERE user_id = ?");
  $stmt->bind_param("i", $user_id);
  $stmt->execute();
  $stmt->close();

  header("Location: {$BASE_URL}/notifications.php");
  exit;
}

// pagination
$page = max(1, (int)($_GET['page'] ?? 1));
$per_page = 10;
$offset = ($page - 1) * $per_page;

// total
$stmt = $mysqli->prepare("SELECT COUNT(*) AS cnt FROM notifications WHERE user_id = ?");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$total_rows = (int)$stmt->get_result()->fetch_assoc()['cnt'];
$stmt->close();

$total_pages = max(1, ceil($total_rows / $per_page));
if ($page > $total_pages) $page = $total_pages;
$offset = ($page - 1) * $per_page;

// fetch
$notifs = [];
$stmt = $mysqli->prepare("
  SELECT notif_id, notif_type, message, log_id, is_read, created_at
  FROM notifications
  WHERE user_id = ?
  ORDER BY created_at DESC
  LIMIT ? OFFSET ?
");
$stmt->bind_param("iii", $user_id, $per_page, $offset);
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
      </div>
      <div class="col-md-4 text-md-end">
        <form method="post">
          <button class="btn btn-outline-light" name="mark_all_read">Mark all as read</button>
        </form>
      </div>
    </div>

    <div class="lr-card">
      <div class="lr-card-body">

        <?php if (count($notifs) === 0): ?>
          <div class="lr-stat-subtext">No notifications yet.</div>
        <?php else: ?>

          <div class="d-grid gap-3">
            <?php foreach ($notifs as $n): ?>
              <?php $isUnread = ((int)$n['is_read'] === 0); ?>
              <div class="p-3 rounded-3 lr-notif-card <?= $isUnread ? 'lr-notif-card-unread' : '' ?>">
                <div class="d-flex justify-content-between align-items-start gap-3">
                  <div>
                    <div class="lr-section-title mb-1"><?= h($n['notif_type']) ?></div>
                    <div><?= h($n['message']) ?></div>
                    <div class="lr-stat-subtext mt-2">
                      <?= h(date("M d, Y • g:i A", strtotime($n['created_at']))) ?>
                    </div>
                  </div>

                  <?php if (!empty($n['log_id'])): ?>
                    <?php
                      $log_id = (int)$n['log_id'];
                      $role = $_SESSION['role'] ?? 'user';
                      $href = ($role === 'trainer')
                        ? "{$BASE_URL}/coach/review-session.php?log_id={$log_id}"
                        : (($role === 'admin')
                          ? "{$BASE_URL}/admin/session-view.php?log_id={$log_id}"
                          : "{$BASE_URL}/trainee/session-view.php?log_id={$log_id}");
                    ?>
                    <a class="btn btn-sm btn-outline-light" href="<?= h($href) ?>">
                      Open
                    </a>
                  <?php endif; ?>
                </div>
              </div>
            <?php endforeach; ?>
          </div>

          <?php if ($total_pages > 1): ?>
            <div class="d-flex justify-content-between align-items-center mt-3">
              <div class="lr-stat-subtext">
                Showing <?= ($offset + 1) ?>–<?= min($offset + $per_page, $total_rows) ?> of <?= $total_rows ?>
              </div>

              <ul class="pagination pagination-sm mb-0">
                <li class="page-item<?= $page <= 1 ? ' disabled' : '' ?>">
                  <a class="page-link" href="<?= $BASE_URL ?>/notifications.php?page=<?= $page-1 ?>">Prev</a>
                </li>

                <?php for ($p=1; $p <= $total_pages; $p++): ?>
                  <li class="page-item<?= $p === $page ? ' active' : '' ?>">
                    <a class="page-link" href="<?= $BASE_URL ?>/notifications.php?page=<?= $p ?>"><?= $p ?></a>
                  </li>
                <?php endfor; ?>

                <li class="page-item<?= $page >= $total_pages ? ' disabled' : '' ?>">
                  <a class="page-link" href="<?= $BASE_URL ?>/notifications.php?page=<?= $page+1 ?>">Next</a>
                </li>
              </ul>
            </div>
          <?php endif; ?>

        <?php endif; ?>

      </div>
    </div>

  </div>
</div>

<?php require __DIR__ . '/includes/footer.php'; ?>
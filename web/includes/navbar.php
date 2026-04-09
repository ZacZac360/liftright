<?php
// liftright/web/includes/navbar.php
global $BASE_URL;
global $mysqli;

require_once __DIR__ . '/db_helpers.php';

$role = $_SESSION['role'] ?? null;
$full_name = $_SESSION['full_name'] ?? null;
$user_id = (int)($_SESSION['user_id'] ?? 0);

// --- Profile photo (pull latest approved from DB so navbar updates immediately after admin approval) ---
$profile_photo = null;

if ($user_id > 0 && isset($mysqli) && $mysqli instanceof mysqli) {
  $stmt = $mysqli->prepare("SELECT profile_photo FROM users WHERE user_id = ? LIMIT 1");
  $stmt->bind_param("i", $user_id);
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
  $stmt->close();

  if ($row && !empty($row['profile_photo'])) {
    $profile_photo = (string)$row['profile_photo']; // e.g. uploads/profile_photos/user_5.jpg
  }
}

// --- Theme: ensure session has a theme (lazy-load from DB) ---
$allowedThemes = ['default','light','dark','contrast'];

if (!isset($_SESSION['theme']) || !in_array($_SESSION['theme'], $allowedThemes, true)) {
  $_SESSION['theme'] = 'default';
  if ($user_id > 0 && isset($mysqli) && $mysqli instanceof mysqli) {
    $stmt = $mysqli->prepare("SELECT theme FROM users WHERE user_id = ? LIMIT 1");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if ($row && !empty($row['theme']) && in_array($row['theme'], $allowedThemes, true)) {
      $_SESSION['theme'] = $row['theme'];
    }
  }
}

$theme = $_SESSION['theme'];

require_once __DIR__ . '/text_helpers.php';

function initials(string $name): string {
  $parts = preg_split('/\s+/', trim($name));
  $a = $parts[0][0] ?? 'U';
  $b = $parts[count($parts)-1][0] ?? '';
  return strtoupper($a . $b);
}

function pending_trainer_apps_count(mysqli $db): int {
  if (!table_exists($db, 'trainer_applications')) return 0;
  $stmt = $db->prepare("SELECT COUNT(*) AS c FROM trainer_applications WHERE status = 'pending'");
  if (!$stmt) return 0;
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
  $stmt->close();
  return (int)($row['c'] ?? 0);
}

function unread_count(mysqli $db, int $user_id, string $table): int {
  if ($user_id <= 0) return 0;

  $allowed = ['notifications', 'messages'];
  if (!in_array($table, $allowed, true)) return 0;
  if (!table_exists($db, $table)) return 0;

  if ($table === 'notifications') {
    $sql = "SELECT COUNT(*) AS c FROM notifications WHERE user_id = ? AND is_read = 0";
  } else {
    $sql = "SELECT COUNT(*) AS c FROM messages WHERE recipient_id = ? AND is_read = 0";
  }

  $stmt = $db->prepare($sql);
  $stmt->bind_param("i", $user_id);
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
  $stmt->close();

  return (int)($row['c'] ?? 0);
}

function pending_invites_count(mysqli $db, int $trainer_id): int {
  if ($trainer_id <= 0) return 0;
  if (!table_exists($db, 'trainer_invites')) return 0;

  $stmt = $db->prepare("
    SELECT COUNT(*) AS c
    FROM trainer_invites
    WHERE trainer_id = ? AND status = 'pending'
  ");
  $stmt->bind_param("i", $trainer_id);
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
  $stmt->close();
  return (int)($row['c'] ?? 0);
}

/* ---------- Admin badges (privacy-safe counts) ---------- */
function pending_accounts_count(mysqli $db): int {
  if (!table_exists($db, 'users')) return 0;
  // account_status column assumed; if not present, return 0 safely
  // We'll just try query; if it fails, catch outside (not here) isn't possible.
  $stmt = $db->prepare("SELECT COUNT(*) AS c FROM users WHERE account_status = 'pending'");
  if (!$stmt) return 0;
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
  $stmt->close();
  return (int)($row['c'] ?? 0);
}

function pending_profile_requests_count(mysqli $db): int {
  if (!table_exists($db, 'profile_change_requests')) return 0;
  $stmt = $db->prepare("SELECT COUNT(*) AS c FROM profile_change_requests WHERE status = 'pending'");
  if (!$stmt) return 0;
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
  $stmt->close();
  return (int)($row['c'] ?? 0);
}

function fetch_latest_notifications(mysqli $db, int $user_id, int $limit = 5): array {
  if ($user_id <= 0) return [];
  if (!table_exists($db, 'notifications')) return [];

  $rows = [];
  $stmt = $db->prepare("
    SELECT notif_id, notif_type, message, log_id, is_read, created_at
    FROM notifications
    WHERE user_id = ?
    ORDER BY created_at DESC
    LIMIT ?
  ");
  $stmt->bind_param("ii", $user_id, $limit);
  $stmt->execute();
  $res = $stmt->get_result();
  while ($r = $res->fetch_assoc()) $rows[] = $r;
  $stmt->close();
  return $rows;
}

function fetch_latest_messages(mysqli $db, int $user_id, int $limit = 5): array {
  if ($user_id <= 0) return [];
  if (!table_exists($db, 'messages')) return [];

  $rows = [];
  $stmt = $db->prepare("
    SELECT m.message_id, m.sender_id, u.full_name AS sender_name,
           m.subject, m.body, m.log_id, m.is_read, m.created_at
    FROM messages m
    JOIN users u ON u.user_id = m.sender_id
    WHERE m.recipient_id = ?
    ORDER BY m.created_at DESC
    LIMIT ?
  ");
  $stmt->bind_param("ii", $user_id, $limit);
  $stmt->execute();
  $res = $stmt->get_result();
  while ($r = $res->fetch_assoc()) $rows[] = $r;
  $stmt->close();
  return $rows;
}

/* ---------- Counts + dropdown items ---------- */
$notif_unread = (isset($mysqli) && $mysqli instanceof mysqli) ? unread_count($mysqli, $user_id, 'notifications') : 0;
$msg_unread   = (isset($mysqli) && $mysqli instanceof mysqli) ? unread_count($mysqli, $user_id, 'messages') : 0;

$invite_unread = (
  $role === 'trainer' &&
  isset($mysqli) && $mysqli instanceof mysqli
) ? pending_invites_count($mysqli, $user_id) : 0;

$notif_items = (isset($mysqli) && $mysqli instanceof mysqli) ? fetch_latest_notifications($mysqli, $user_id, 5) : [];
$msg_items   = (isset($mysqli) && $mysqli instanceof mysqli) ? fetch_latest_messages($mysqli, $user_id, 5) : [];

/* ---------- Admin badge counts ---------- */

$pending_accounts = (
  $role === 'admin' &&
  isset($mysqli) && $mysqli instanceof mysqli
) ? pending_accounts_count($mysqli) : 0;

$pending_unlink_requests = (
  $role === 'admin' &&
  isset($mysqli) && $mysqli instanceof mysqli
) ? pending_unlink_requests_count($mysqli) : 0;

// one badge for the Users tab (pending accounts + unlink requests)
$users_badge = (int)$pending_accounts + (int)$pending_unlink_requests;

$pending_trainer_apps = (
  $role === 'admin' &&
  isset($mysqli) && $mysqli instanceof mysqli
) ? pending_trainer_apps_count($mysqli) : 0;

$pending_profile_requests = (
  $role === 'admin' &&
  isset($mysqli) && $mysqli instanceof mysqli
) ? pending_profile_requests_count($mysqli) : 0;

/* ---------- Role-aware routes ---------- */
$dashboard_href = $BASE_URL . '/index.php';
$profile_href   = $BASE_URL . '/index.php';

if ($role === 'user') {
  $dashboard_href = $BASE_URL . '/trainee/dashboard.php';
  $profile_href   = $BASE_URL . '/trainee/profile.php'; // create later if needed
} elseif ($role === 'trainer') {
  $dashboard_href = $BASE_URL . '/coach/dashboard.php';
  $profile_href   = $BASE_URL . '/coach/profile.php';
} elseif ($role === 'admin') {
  $dashboard_href = $BASE_URL . '/admin/dashboard.php';
  $profile_href   = $BASE_URL . '/admin/profile.php'; // create later if needed
}
$currentPath = parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH) ?: '';

function nav_active(string $needle, string $currentPath): string {
  return str_contains($currentPath, $needle) ? ' active' : '';
}

// Notifications "open" target when log_id exists
function notif_open_href(string $baseUrl, string $role, int $log_id): string {
  if ($log_id <= 0) return $baseUrl . '/notifications.php';
  return match($role) {
    'trainer' => $baseUrl . "/coach/review-session.php?log_id={$log_id}",
    'admin'   => $baseUrl . "/admin/session-view.php?log_id={$log_id}", // optional later
    default   => $baseUrl . "/trainee/session-view.php?log_id={$log_id}",
  };
}
?>
<nav class="navbar navbar-expand-lg fixed-top liftright-navbar">
  <div class="container">
    <a class="navbar-brand d-flex align-items-center gap-2" href="<?= $BASE_URL ?>/index.php">
      <img src="<?= $BASE_URL ?>/assets/images/logo/liftright-logo.png"
            alt="LiftRight Logo"
            class="lr-logo">

      <div class="d-flex flex-column">
        <span class="brand-accent">LiftRight</span>
        <span class="brand-subtitle">Real-time posture + fatigue insights</span>
      </div>
    </a>

    <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#lrNav">
      <span class="navbar-toggler-icon"></span>
    </button>

    <div class="collapse navbar-collapse" id="lrNav">
      <ul class="navbar-nav ms-auto align-items-lg-center gap-lg-2">

        <?php if (!$role): ?>
          <li class="nav-item"><a class="nav-link" href="<?= $BASE_URL ?>/login.php">Login</a></li>
          <li class="nav-item"><a class="btn btn-primary btn-sm" href="<?= $BASE_URL ?>/register.php">Create account</a></li>
        <?php else: ?>

          <?php if ($role === 'user'): ?>
            <li class="nav-item"><a class="nav-link<?= nav_active('/trainee/dashboard.php', $currentPath) ?>" href="<?= $BASE_URL ?>/trainee/dashboard.php">Dashboard</a></li>
            <li class="nav-item"><a class="nav-link<?= nav_active('/trainee/sessions.php', $currentPath) || nav_active('/trainee/session-view.php', $currentPath) ? ' active' : '' ?>" href="<?= $BASE_URL ?>/trainee/sessions.php">Sessions</a></li>
            <li class="nav-item"><a class="nav-link<?= nav_active('/trainee/assign-trainer.php', $currentPath) ? ' active' : '' ?>" href="<?= $BASE_URL ?>/trainee/assign-trainer.php">Assign Trainer</a></li>
            <li class="nav-item">
              <a class="nav-link<?= nav_active('/trainee/trainer-info.php', $currentPath) ? ' active' : '' ?>" href="<?= $BASE_URL ?>/trainee/trainer-info.php">
                Trainer Info
              </a>
            </li>
          <?php elseif ($role === 'trainer'): ?>
            <li class="nav-item"><a class="nav-link<?= nav_active('/coach/dashboard.php', $currentPath) ? ' active' : '' ?>" href="<?= $BASE_URL ?>/coach/dashboard.php">Dashboard</a></li>
            <li class="nav-item"><a class="nav-link<?= nav_active('/coach/review-history.php', $currentPath) || nav_active('/coach/review-session.php', $currentPath) ? ' active' : '' ?>" href="<?= $BASE_URL ?>/coach/review-history.php">Review History</a></li>
            
            <li class="nav-item">
              <a class="nav-link d-flex align-items-center gap-2<?= nav_active('/coach/invitations.php', $currentPath) ? ' active' : '' ?>" href="<?= $BASE_URL ?>/coach/invitations.php">
                Invitations
                <?php if ($invite_unread > 0): ?>
                  <span class="lr-dot-pill"><?= (int)$invite_unread ?></span>
                <?php endif; ?>
              </a>
            </li>

            <li class="nav-item">
              <a class="nav-link<?= nav_active('/coach/reviews.php', $currentPath) ? ' active' : '' ?>" href="<?= $BASE_URL ?>/coach/reviews.php">
                Reviews
              </a>
            </li>

          <?php elseif ($role === 'admin'): ?>
            <li class="nav-item"><a class="nav-link<?= nav_active('/admin/dashboard.php', $currentPath) ? ' active' : '' ?>" href="<?= $BASE_URL ?>/admin/dashboard.php">Dashboard</a></li>
            
           <a class="nav-link d-flex align-items-center gap-2<?= nav_active('/admin/users.php', $currentPath) ? ' active' : '' ?>" href="<?= $BASE_URL ?>/admin/users.php">
              Users
              <?php if ($users_badge > 0): ?>
                <span class="lr-dot-pill"><?= (int)$users_badge ?></span>
              <?php endif; ?>
            </a>
            
            <li class="nav-item">
              <a class="nav-link d-flex align-items-center gap-2<?= nav_active('/admin/trainer-applications.php', $currentPath) ? ' active' : '' ?>" href="<?= $BASE_URL ?>/admin/trainer-applications.php">
                Trainer Apps
                <?php if ($pending_trainer_apps > 0): ?>
                  <span class="lr-dot-pill"><?= (int)$pending_trainer_apps ?></span>
                <?php endif; ?>
              </a>
            </li>
            <li class="nav-item">
              <a class="nav-link<?= nav_active('/admin/audit-logs.php', $currentPath) ? ' active' : '' ?>" href="<?= $BASE_URL ?>/admin/audit-logs.php">Audit Logs</a>
            </li>
            <li class="nav-item">
              <a class="nav-link d-flex align-items-center gap-2" href="<?= $BASE_URL ?>/admin/profile-requests.php">
                Profile Requests
                <?php if ($pending_profile_requests > 0): ?>
                  <span class="lr-dot-pill"><?= (int)$pending_profile_requests ?></span>
                <?php endif; ?>
              </a>
            </li>

            <li class="nav-item">
              <a class="nav-link<?= nav_active('/admin/reviews.php', $currentPath) ? ' active' : '' ?>" href="<?= $BASE_URL ?>/admin/reviews.php">
                Review Moderation
              </a>
            </li>

            <li class="nav-item"><a class="nav-link<?= nav_active('/admin/models.php', $currentPath) ? ' active' : '' ?>" href="<?= $BASE_URL ?>/admin/models.php">Models</a></li>
            <li class="nav-item"><a class="nav-link<?= nav_active('/admin/exports.php', $currentPath) ? ' active' : '' ?>" href="<?= $BASE_URL ?>/admin/exports.php">Exports</a></li>
          <?php endif; ?>

          <!-- Icons -->
          <li class="nav-item d-flex align-items-center gap-2 ms-lg-3">

            <!-- Notifications dropdown -->
            <div class="dropdown">
              <button class="lr-icon-btn" type="button"
                      data-bs-toggle="dropdown" data-bs-auto-close="outside"
                      aria-expanded="false" aria-label="Notifications">
                <i class="fa-regular fa-bell"></i>
                <?php if ($notif_unread > 0): ?>
                  <span class="lr-dot-badge"><?= (int)$notif_unread ?></span>
                <?php endif; ?>
              </button>

              <div class="dropdown-menu dropdown-menu-end lr-drop-panel p-0">
                <div class="d-flex justify-content-between align-items-center px-3 py-2 border-bottom">
                  <div class="fw-semibold">Notifications</div>
                  <span class="small text-secondary"><?= (int)$notif_unread ?> unread</span>
                </div>

                <div class="lr-drop-scroll">
                  <?php if (count($notif_items) === 0): ?>
                    <div class="px-3 py-3 lr-stat-subtext">No notifications yet.</div>
                  <?php else: ?>
                    <?php foreach ($notif_items as $n): ?>
                      <?php
                        $isUnread = ((int)$n['is_read'] === 0);
                        $rowStyle = $isUnread ? "background: var(--lr-accent-soft);" : "";
                        $log_id = (int)($n['log_id'] ?? 0);
                        $openHref = notif_open_href($BASE_URL, (string)$role, $log_id);
                      ?>
                      <a class="dropdown-item lr-drop-item px-3 py-2"
                         href="<?= h($openHref) ?>" style="<?= $rowStyle ?>">
                        <div class="d-flex justify-content-between gap-2">
                          <div class="text-capitalize small fw-semibold"><?= h((string)$n['notif_type']) ?></div>
                          <div class="small text-secondary" style="opacity:.85;"><?= h(date("M d", strtotime((string)$n['created_at']))) ?></div>
                        </div>
                        <div class="small"><?= h(lr_snippet((string)$n['message'], 78)) ?></div>
                      </a>
                    <?php endforeach; ?>
                  <?php endif; ?>
                </div>

                <div class="border-top px-3 py-2 d-flex justify-content-between">
                  <a class="btn btn-sm btn-outline-light" href="<?= $BASE_URL ?>/notifications.php">Show all</a>
                  <form method="post" action="<?= $BASE_URL ?>/notifications.php" class="m-0">
                    <button class="btn btn-sm btn-outline-light" name="mark_all_read" value="1" type="submit">
                      Mark read
                    </button>
                  </form>
                </div>
              </div>
            </div>

            <!-- Messages dropdown -->
            <div class="dropdown">
              <button class="lr-icon-btn" type="button"
                      data-bs-toggle="dropdown" data-bs-auto-close="outside"
                      aria-expanded="false" aria-label="Messages">
                <i class="fa-regular fa-envelope"></i>
                <?php if ($msg_unread > 0): ?>
                  <span class="lr-dot-badge"><?= (int)$msg_unread ?></span>
                <?php endif; ?>
              </button>

              <div class="dropdown-menu dropdown-menu-end lr-drop-panel p-0">
                <div class="d-flex justify-content-between align-items-center px-3 py-2 border-bottom">
                  <div class="fw-semibold">Messages</div>
                  <span class="small text-secondary"><?= (int)$msg_unread ?> unread</span>
                </div>

                <div class="lr-drop-scroll">
                  <?php if (count($msg_items) === 0): ?>
                    <div class="px-3 py-3 lr-stat-subtext">No messages yet.</div>
                  <?php else: ?>
                    <?php foreach ($msg_items as $m): ?>
                      <?php
                        $isUnread = ((int)$m['is_read'] === 0);
                        $rowStyle = $isUnread ? "background: var(--lr-accent-soft);" : "";
                        $subject = (string)($m['subject'] ?? '');
                        $preview = $subject !== '' ? $subject : lr_snippet((string)$m['body'], 78);
                      ?>
                      <a class="dropdown-item lr-drop-item px-3 py-2"
                         href="<?= $BASE_URL ?>/messages.php" style="<?= $rowStyle ?>">
                        <div class="d-flex justify-content-between gap-2">
                          <div class="small fw-semibold"><?= h((string)$m['sender_name']) ?></div>
                          <div class="small text-secondary" style="opacity:.85;"><?= h(date("M d", strtotime((string)$m['created_at']))) ?></div>
                        </div>
                        <div class="small"><?= h(lr_snippet($preview, 78)) ?></div>
                      </a>
                    <?php endforeach; ?>
                  <?php endif; ?>
                </div>

                <div class="border-top px-3 py-2 d-flex justify-content-between">
                  <a class="btn btn-sm btn-outline-light" href="<?= $BASE_URL ?>/messages.php">Show all</a>
                  <a class="btn btn-sm btn-outline-light" href="<?= $BASE_URL ?>/compose-message.php?compose=1">Compose</a>
                </div>
              </div>
            </div>

          </li>

          <!-- Profile dropdown -->
          <li class="nav-item dropdown ms-lg-2">
            <a class="nav-link d-flex align-items-center gap-2"
               href="#"
               role="button"
               data-bs-toggle="dropdown"
               aria-expanded="false">
              <?php
                $avatarSrc = '';
                if (!empty($profile_photo)) {
                  $avatarSrc = $BASE_URL . '/' . ltrim((string)$profile_photo, '/');
                }
              ?>
              <div class="avatar-circle" style="overflow:hidden; display:flex; align-items:center; justify-content:center;">
                <?php if ($avatarSrc): ?>
                  <img src="<?= h($avatarSrc) ?>" alt="Profile photo"
                      style="width:100%;height:100%;object-fit:cover;display:block;">
                <?php else: ?>
                  <?= h(initials((string)$full_name)) ?>
                <?php endif; ?>
              </div>
              <div class="d-none d-lg-block small">
                <div class="fw-semibold"><?= h((string)$full_name) ?></div>
                <div class="text-secondary" style="opacity:.85;"><?= h((string)$role) ?></div>
              </div>
            </a>

            <ul class="dropdown-menu dropdown-menu-end">
              <li><a class="dropdown-item" href="<?= h($dashboard_href) ?>"><i class="fa-solid fa-gauge me-2"></i>Dashboard</a></li>
              <li><a class="dropdown-item" href="<?= h($profile_href) ?>"><i class="fa-regular fa-user me-2"></i>Profile</a></li>

              <?php if ($role === 'trainer'): ?>
                <li><a class="dropdown-item" href="<?= $BASE_URL ?>/coach/review-history.php"><i class="fa-regular fa-clipboard me-2"></i>Review History</a></li>
                <li><a class="dropdown-item" href="<?= $BASE_URL ?>/coach/invitations.php">
                  <i class="fa-regular fa-paper-plane me-2"></i>Invitations
                  <?php if ($invite_unread > 0): ?>
                    <span class="ms-2 lr-dot-pill"><?= (int)$invite_unread ?></span>
                  <?php endif; ?>
                </a></li>
                <li class="px-3 py-2">
                  <div class="small fw-semibold mb-1">Theme</div>
                  <select id="lrThemeSelect" class="form-select form-select-sm">
                    <option value="default"  <?= $theme==='default' ? 'selected' : '' ?>>Default</option>
                    <option value="light"    <?= $theme==='light' ? 'selected' : '' ?>>Light</option>
                    <option value="dark"     <?= $theme==='dark' ? 'selected' : '' ?>>Dark</option>
                    <option value="contrast" <?= $theme==='contrast' ? 'selected' : '' ?>>High Contrast</option>
                  </select>
                </li>
              <?php endif; ?>

              <?php if ($role === 'user'): ?>
                <li><a class="dropdown-item" href="<?= $BASE_URL ?>/trainee/assign-trainer.php"><i class="fa-regular fa-id-badge me-2"></i>Assign Trainer</a></li>
                <li class="nav-item">
                  <a class="nav-link" href="<?= $BASE_URL ?>/trainee/trainer-info.php">
                    Trainer Info
                  </a>
                </li>
                <li><hr class="dropdown-divider"></li>

                <li class="px-3 py-2">
                  <div class="small fw-semibold mb-1">Theme</div>
                  <select id="lrThemeSelect" class="form-select form-select-sm">
                    <option value="default"  <?= $theme==='default' ? 'selected' : '' ?>>Default</option>
                    <option value="light"    <?= $theme==='light' ? 'selected' : '' ?>>Light</option>
                    <option value="dark"     <?= $theme==='dark' ? 'selected' : '' ?>>Dark</option>
                    <option value="contrast" <?= $theme==='contrast' ? 'selected' : '' ?>>High Contrast</option>
                  </select>
                </li>
              
                <?php endif; ?>

              <?php if ($role === 'admin'): ?>
                <li>
                  <a class="dropdown-item d-flex align-items-center justify-content-between" href="<?= $BASE_URL ?>/admin/users.php">
                    <span><i class="fa-solid fa-users me-2"></i>Users</span>
                    <?php if ($users_badge > 0): ?>
                      <span class="lr-dot-pill"><?= (int)$users_badge ?></span>
                    <?php endif; ?>
                  </a>
                </li>

                <li>
                  <a class="dropdown-item d-flex align-items-center justify-content-between" href="<?= $BASE_URL ?>/admin/trainer-applications.php">
                    <span><i class="fa-regular fa-id-badge me-2"></i>Trainer Apps</span>
                    <?php if ($pending_trainer_apps > 0): ?>
                      <span class="lr-dot-pill"><?= (int)$pending_trainer_apps ?></span>
                    <?php endif; ?>
                  </a>
                </li>
                <li>
                  <a class="nav-link d-flex align-items-center gap-2<?= nav_active('/admin/profile-requests.php', $currentPath) ? ' active' : '' ?>" href="<?= $BASE_URL ?>/admin/profile-requests.php">
                    <span><i class="fa-regular fa-pen-to-square me-2"></i>Profile Requests</span>
                    <?php if ($pending_profile_requests > 0): ?>
                      <span class="lr-dot-pill"><?= (int)$pending_profile_requests ?></span>
                    <?php endif; ?>
                  </a>
                </li>
                <li><a class="dropdown-item" href="<?= $BASE_URL ?>/admin/models.php"><i class="fa-solid fa-microchip me-2"></i>Models</a></li>
                <li><a class="dropdown-item" href="<?= $BASE_URL ?>/admin/exports.php"><i class="fa-solid fa-download me-2"></i>Exports</a></li>
              <?php endif; ?>

              <li><hr class="dropdown-divider"></li>
              <li><a class="dropdown-item" href="<?= $BASE_URL ?>/logout.php"><i class="fa-solid fa-right-from-bracket me-2"></i>Logout</a></li>
            </ul>
          </li>

        <?php endif; ?>

      </ul>
    </div>
  </div>
</nav>

<script>
(function(){
  const sel = document.getElementById('lrThemeSelect');
  if (!sel) return;

  const base = document.querySelector('meta[name="lr-base-url"]')?.getAttribute('content') || '';
  sel.addEventListener('change', async () => {
    const theme = sel.value;

    // apply instantly (no refresh)
    document.documentElement.setAttribute('data-theme', theme);

    try{
      const res = await fetch(base + '/api/set-theme.php', {
        method: 'POST',
        headers: {'Content-Type':'application/json'},
        body: JSON.stringify({theme})
      });
      const data = await res.json();
      if (!data.success) throw new Error(data.message || 'Save failed');
    } catch (e) {
      console.error(e);
      // fallback: revert select if save failed
      // (optional) alert('Theme save failed');
    }
  });
})();
</script>
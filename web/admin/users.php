<?php
// liftright/web/admin/users.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';
require_once __DIR__ . '/../includes/db_helpers.php';
require_once __DIR__ . '/../config/audit.php';

require_role(['admin']);

$page_title = "Manage Users";

$flash = null;
$flash_kind = 'dark';

/* ---------- Helpers (guarded to avoid redeclare errors) ---------- */
if (!function_exists('fmtDT')) {
  function fmtDT(?string $dt): string {
    if (!$dt) return "—";
    $ts = strtotime($dt);
    return $ts ? date("M d, Y • g:i A", $ts) : $dt;
  }
}
if (!function_exists('badgeStatusClass')) {
  function badgeStatusClass(string $status): string {
    return match ($status) {
      'approved'  => 'lr-badge lr-badge-good',
      'pending'   => 'lr-badge lr-badge-warning',
      'rejected'  => 'lr-badge lr-badge-danger',
      'suspended' => 'lr-badge lr-badge-danger',
      default     => 'lr-badge lr-badge-warning',
    };
  }
}

/* ---------- Handle actions ---------- */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $action  = (string)($_POST['action'] ?? '');
  $user_id = (int)($_POST['user_id'] ?? 0);
  $admin_password = (string)($_POST['admin_password'] ?? '');

  try {
    if ($user_id <= 0) throw new Exception("Invalid user.");

    $self_id = (int)($_SESSION['user_id'] ?? 0);

    // Helper: add admin notification (optional, safe if table exists)
    $canNotify = false;
    if (isset($mysqli) && $mysqli instanceof mysqli) {
      $chk = $mysqli->prepare("
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = DATABASE() AND table_name = 'notifications'
        LIMIT 1
      ");
      $chk->execute();
      $r = $chk->get_result();
      $canNotify = ($r && $r->num_rows > 0);
      $chk->close();
    }

    if ($action === 'set_role') {
      $new_role = (string)($_POST['new_role'] ?? 'user');
      if (!in_array($new_role, ['user','trainer','admin'], true)) {
        throw new Exception("Invalid role.");
      }
      if ($user_id === $self_id && $new_role !== 'admin') {
        throw new Exception("You can't remove your own admin role while logged in.");
      }

      $before = audit_fetch_user_brief($mysqli, $user_id);

      $stmt = $mysqli->prepare("UPDATE users SET role=? WHERE user_id=?");
      $stmt->bind_param("si", $new_role, $user_id);
      $stmt->execute();
      $stmt->close();

      $after = audit_fetch_user_brief($mysqli, $user_id);

      audit_admin_action($mysqli, $self_id, 'admin_set_role', $user_id, [
        'before' => $before,
        'after' => $after,
        'new_role' => $new_role
      ]);

      $flash = "Updated user role successfully.";
      $flash_kind = 'success';
    }

    elseif ($action === 'set_status') {
      $new_status = (string)($_POST['new_status'] ?? 'pending');
      if (!in_array($new_status, ['pending','approved','rejected','suspended'], true)) {
        throw new Exception("Invalid status.");
      }
      if ($user_id === $self_id && $new_status !== 'approved') {
        throw new Exception("You can't change your own account status while logged in.");
      }

      $before = audit_fetch_user_brief($mysqli, $user_id);

      $stmt = $mysqli->prepare("UPDATE users SET account_status=? WHERE user_id=?");
      $stmt->bind_param("si", $new_status, $user_id);
      $stmt->execute();
      $stmt->close();

      $after = audit_fetch_user_brief($mysqli, $user_id);

      audit_admin_action($mysqli, $self_id, 'admin_set_status', $user_id, [
        'before' => $before,
        'after' => $after,
        'new_status' => $new_status
      ]);

      // Optional: notify the user
      if ($canNotify) {
        $msg = match ($new_status) {
          'approved'  => "Your LiftRight account has been approved.",
          'rejected'  => "Your LiftRight account was rejected. Please contact the administrator.",
          'suspended' => "Your LiftRight account has been suspended. Please contact the administrator.",
          default     => "Your LiftRight account status changed to: {$new_status}.",
        };

        $type = 'system';
        $from = $self_id ?: null;

        // from_user_id is nullable
        if ($from) {
          $ins = $mysqli->prepare("
            INSERT INTO notifications (user_id, notif_type, message, from_user_id)
            VALUES (?, ?, ?, ?)
          ");
          $ins->bind_param("issi", $user_id, $type, $msg, $from);
        } else {
          $ins = $mysqli->prepare("
            INSERT INTO notifications (user_id, notif_type, message, from_user_id)
            VALUES (?, ?, ?, NULL)
          ");
          $ins->bind_param("iss", $user_id, $type, $msg);
        }
        $ins->execute();
        $ins->close();
      }

      $flash = "Updated account status successfully.";
      $flash_kind = 'success';
    }
    
    elseif ($action === 'unlink_trainer') {

      // Get current trainer_id BEFORE unlinking
      $stmt = $mysqli->prepare("SELECT trainer_id FROM users WHERE user_id=? AND role='user' LIMIT 1");
      $stmt->bind_param("i", $user_id);
      $stmt->execute();
      $row = $stmt->get_result()->fetch_assoc();
      $stmt->close();

      $trainer_id = (int)($row['trainer_id'] ?? 0);
      if ($trainer_id <= 0) {
        throw new Exception("This trainee is not currently linked to a trainer.");
      }

      $mysqli->begin_transaction();

      try {

        // 1) Unlink in users table
        $stmt = $mysqli->prepare("UPDATE users SET trainer_id = NULL WHERE user_id=? AND role='user' LIMIT 1");
        $stmt->bind_param("i", $user_id);
        $stmt->execute();
        $stmt->close();

        // 2) Resolve unlink request WITHOUT UNIQUE collision
        if (table_exists($mysqli, 'trainer_invites')) {

          // 2a) Find latest unlink_requested invite for this pair
          $stmt = $mysqli->prepare("
            SELECT invite_id
            FROM trainer_invites
            WHERE trainee_id=? AND trainer_id=? AND status='unlink_requested'
            ORDER BY created_at DESC
            LIMIT 1
          ");
          $stmt->bind_param("ii", $user_id, $trainer_id);
          $stmt->execute();
          $inv = $stmt->get_result()->fetch_assoc();
          $stmt->close();

          if ($inv) {
            $invite_id = (int)$inv['invite_id'];

            // 2b) Delete any existing cancelled row for this pair (prevents duplicate key on update)
            $stmt = $mysqli->prepare("
              DELETE FROM trainer_invites
              WHERE trainee_id=? AND trainer_id=? AND status='cancelled' AND invite_id <> ?
            ");
            $stmt->bind_param("iii", $user_id, $trainer_id, $invite_id);
            $stmt->execute();
            $stmt->close();

            // 2c) Now it's safe to mark unlink_requested as cancelled
            $stmt = $mysqli->prepare("
              UPDATE trainer_invites
              SET status='cancelled', responded_at=NOW()
              WHERE invite_id = ?
              LIMIT 1
            ");
            $stmt->bind_param("i", $invite_id);
            $stmt->execute();
            $stmt->close();

          } else {
            // No unlink_requested row exists. (Optional) clean up: mark latest accepted/pending as cancelled.
            $stmt = $mysqli->prepare("
              UPDATE trainer_invites
              SET status='cancelled', responded_at=NOW()
              WHERE trainee_id=? AND trainer_id=? AND status IN ('accepted','pending')
              ORDER BY created_at DESC
              LIMIT 1
            ");
            $stmt->bind_param("ii", $user_id, $trainer_id);
            $stmt->execute();
            $stmt->close();
          }
        }

        // Optional: notify trainee
        if ($canNotify) {
          $type = 'system';
          $msg  = "Your trainer unlink request has been approved.";
          $from = $self_id ?: null;

          if ($from) {
            $ins = $mysqli->prepare("
              INSERT INTO notifications (user_id, notif_type, message, from_user_id)
              VALUES (?, ?, ?, ?)
            ");
            $ins->bind_param("issi", $user_id, $type, $msg, $from);
          } else {
            $ins = $mysqli->prepare("
              INSERT INTO notifications (user_id, notif_type, message, from_user_id)
              VALUES (?, ?, ?, NULL)
            ");
            $ins->bind_param("iss", $user_id, $type, $msg);
          }
          $ins->execute();
          $ins->close();
        }

        $mysqli->commit();

        audit_admin_action($mysqli, $self_id, 'admin_unlink_trainer', $user_id, [
          'trainer_id' => $trainer_id
        ]);

        $flash = "Unlinked trainer successfully.";
        $flash_kind = 'success';

      } catch (Throwable $e) {
        $mysqli->rollback();
        throw $e;
      }
    }

    elseif ($action === 'delete_user') {
      if ($user_id === $self_id) {
        throw new Exception("You can't delete your own account while logged in.");
      }

      require_admin_password_confirm($mysqli, $self_id, $admin_password);

      $before = audit_fetch_user_brief($mysqli, $user_id);
      if (!$before) {
        throw new Exception("User not found.");
      }

      $stmt = $mysqli->prepare("DELETE FROM users WHERE user_id=?");
      $stmt->bind_param("i", $user_id);
      $stmt->execute();
      $stmt->close();

      audit_admin_action($mysqli, $self_id, 'admin_delete_user', $user_id, [
        'deleted_user' => $before
      ]);

      $flash = "Deleted user successfully.";
      $flash_kind = 'success';
    }

    else {
      throw new Exception("Unknown action.");
    }

  } catch (Throwable $e) {
    $flash = "Error: " . $e->getMessage();
    $flash_kind = 'danger';
  }
}

/* ---------- Filters ---------- */
$q            = trim((string)($_GET['q'] ?? ''));
$roleFilter   = trim((string)($_GET['role'] ?? ''));
$statusFilter = trim((string)($_GET['status'] ?? ''));

// Paging (single source of truth)
$page = (int)($_GET['page'] ?? 1);
$per_page = (int)($_GET['per_page'] ?? 25);
if ($page < 1) $page = 1;

$allowedPP = [10,25,50,100];
if (!in_array($per_page, $allowedPP, true)) $per_page = 25;

$allowedRoles  = ['user','trainer','admin'];
$allowedStatus = ['pending','approved','rejected','suspended'];

// URL builder for pagination links
function build_query(array $overrides = []): string {
  $q = $_GET;
  foreach ($overrides as $k => $v) {
    if ($v === null) unset($q[$k]);
    else $q[$k] = $v;
  }
  return http_build_query($q);
}

/* ---------- Query (COUNT + DATA) ---------- */
$users = [];

$baseFrom = "
  FROM users u
  LEFT JOIN users t ON t.user_id = u.trainer_id
  WHERE u.role <> 'admin'
";

$where = "";
$types = "";
$params = [];

if ($q !== '') {
  $where .= " AND (u.full_name LIKE CONCAT('%', ?, '%')
               OR u.email LIKE CONCAT('%', ?, '%')
               OR CAST(u.user_id AS CHAR) = ?)";
  $types .= "sss";
  $params[] = $q;
  $params[] = $q;
  $params[] = $q;
}

if (in_array($roleFilter, $allowedRoles, true)) {
  // Note: base excludes admin already; choosing "admin" will show none (expected)
  $where .= " AND u.role = ?";
  $types .= "s";
  $params[] = $roleFilter;
}

if (in_array($statusFilter, $allowedStatus, true)) {
  $where .= " AND u.account_status = ?";
  $types .= "s";
  $params[] = $statusFilter;
}

// COUNT
$countSql = "SELECT COUNT(*) AS cnt {$baseFrom} {$where}";
$stmt = $mysqli->prepare($countSql);
if ($types !== "") {
  $stmt->bind_param($types, ...$params);
}
$stmt->execute();
$total_rows = (int)($stmt->get_result()->fetch_assoc()['cnt'] ?? 0);
$stmt->close();

$total_pages = max(1, (int)ceil($total_rows / $per_page));
if ($page > $total_pages) $page = $total_pages;
$offset = ($page - 1) * $per_page;

// DATA
$dataSql = "
  SELECT
    u.user_id,
    u.full_name,
    u.email,
    u.role,
    u.age,
    u.account_status,
    u.trainer_id,
    t.full_name AS trainer_name,
    u.created_at,
    u.last_login
  {$baseFrom}
  {$where}
  ORDER BY u.created_at DESC
  LIMIT ? OFFSET ?
";

$types2 = $types . "ii";
$params2 = $params;
$params2[] = $per_page;
$params2[] = $offset;

$stmt = $mysqli->prepare($dataSql);
$stmt->bind_param($types2, ...$params2);
$stmt->execute();
$res = $stmt->get_result();
while ($r = $res->fetch_assoc()) $users[] = $r;
$stmt->close();

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="lr-page-wrapper">
  <div class="container lr-main-container py-4">

    <div class="row mb-3 align-items-center">
      <div class="col-md-8">
        <div class="lr-section-title mb-1">Administration</div>
        <h1 class="lr-section-heading mb-1">Manage Users</h1>
        <p class="lr-stat-subtext mb-0">Approve accounts, edit roles, audit logins, manage trainer links, and remove users.</p>
      </div>
    </div>

    <?php if ($flash): ?>
      <div class="alert alert-<?= h($flash_kind) ?> border border-secondary">
        <?= h($flash) ?>
      </div>
    <?php endif; ?>

    <!-- Filters -->
    <div class="lr-card mb-3">
      <div class="lr-card-body">
        <form class="row g-2 align-items-end" method="GET" action="">
          <div class="col-md-5">
            <label class="form-label lr-stat-label">Search</label>
            <input class="form-control" name="q" value="<?= h($q) ?>"
                   placeholder="Name, email, or User ID...">
          </div>

          <div class="col-md-3">
            <label class="form-label lr-stat-label">Role</label>
            <select class="form-select" name="role">
              <option value="">All roles</option>
              <option value="user" <?= $roleFilter==='user'?'selected':'' ?>>user (trainee)</option>
              <option value="trainer" <?= $roleFilter==='trainer'?'selected':'' ?>>trainer (coach)</option>
              <option value="admin" <?= $roleFilter==='admin'?'selected':'' ?>>admin</option>
            </select>
          </div>

          <div class="col-md-2">
            <label class="form-label lr-stat-label">Status</label>
            <select class="form-select" name="status">
              <option value="">All</option>
              <option value="pending" <?= $statusFilter==='pending'?'selected':'' ?>>pending</option>
              <option value="approved" <?= $statusFilter==='approved'?'selected':'' ?>>approved</option>
              <option value="rejected" <?= $statusFilter==='rejected'?'selected':'' ?>>rejected</option>
              <option value="suspended" <?= $statusFilter==='suspended'?'selected':'' ?>>suspended</option>
            </select>
          </div>

          <div class="col-md-2">
            <label class="form-label lr-stat-label">Per page</label>
            <select class="form-select" name="per_page">
              <?php foreach ([10,25,50,100] as $pp): ?>
                <option value="<?= $pp ?>" <?= ($per_page===$pp)?'selected':'' ?>><?= $pp ?></option>
              <?php endforeach; ?>
            </select>
          </div>

          <input type="hidden" name="page" value="1">

          <div class="col-md-2 d-grid">
            <button class="btn btn-primary" type="submit">
              <i class="fa-solid fa-magnifying-glass me-2"></i>Apply
            </button>
          </div>

          <div class="col-12 mt-2">
            <a class="btn btn-sm btn-outline-light" href="<?= $BASE_URL ?>/admin/users.php">Reset</a>
          </div>
        </form>
      </div>
    </div>

    <!-- Users table -->
    <div class="lr-card">
      <div class="lr-card-header d-flex justify-content-between align-items-center">
        <div>
          <div class="lr-section-title mb-1">Accounts</div>
          <div class="lr-section-heading mb-0">Users</div>
        </div>
        <div class="lr-stat-subtext mb-0">
          Showing <?= ($total_rows === 0) ? 0 : ($offset + 1) ?>–<?= min($offset + $per_page, $total_rows) ?>
          of <?= (int)$total_rows ?>
        </div>
      </div>

      <div class="lr-card-body p-0">
        <div class="table-responsive">
          <table class="table table-hovermb-0 table-lr-dark">
            <thead>
              <tr>
                <th>User</th>
                <th>Role</th>
                <th>Status</th>
                <th>Trainer</th>
                <th>Created</th>
                <th>Last login</th>
                <th class="text-end">Actions</th>
              </tr>
            </thead>

            <tbody>
            <?php if (!$users): ?>
              <tr>
                <td colspan="7" class="text-center py-4 lr-stat-subtext">No users found.</td>
              </tr>
            <?php else: ?>
              <?php foreach ($users as $u): ?>
                <?php
                  $uid = (int)$u['user_id'];
                  $role = (string)$u['role'];
                  $status = (string)($u['account_status'] ?? 'pending');
                  $trainerName = (string)($u['trainer_name'] ?? '');
                  $trainerId = (int)($u['trainer_id'] ?? 0);
                  $self_id = (int)($_SESSION['user_id'] ?? 0);
                  $isSelf = ($uid === $self_id);
                ?>
                <tr>
                  <td>
                    <div class="fw-semibold"><?= h((string)$u['full_name']) ?></div>
                    <div class="lr-stat-subtext"><?= h((string)$u['email']) ?> • #<?= $uid ?></div>
                  </td>

                  <td><span class="lr-chip-exercise text-capitalize"><?= h($role) ?></span></td>

                  <td>
                    <span class="<?= h(badgeStatusClass($status)) ?> text-capitalize">
                      <?= h($status) ?>
                    </span>
                  </td>

                  <td>
                    <?php if ($role !== 'user'): ?>
                      <span class="lr-stat-subtext">—</span>
                    <?php else: ?>
                      <?php if ($trainerId > 0): ?>
                        <div class="fw-semibold"><?= h($trainerName !== '' ? $trainerName : ("Trainer #".$trainerId)) ?></div>
                        <div class="lr-stat-subtext">trainer_id: <?= (int)$trainerId ?></div>
                      <?php else: ?>
                        <span class="lr-stat-subtext">Unassigned</span>
                      <?php endif; ?>
                    <?php endif; ?>
                  </td>

                  <td><?= h(date("M d, Y", strtotime((string)$u['created_at']))) ?></td>
                  <td><?= $u['last_login'] ? h(fmtDT((string)$u['last_login'])) : '—' ?></td>

                  <td class="text-end">
                    <!-- Status -->
                    <form method="POST" class="d-inline-flex gap-2 align-items-center">
                      <input type="hidden" name="user_id" value="<?= $uid ?>">
                      <input type="hidden" name="action" value="set_status">
                      <select class="form-select form-select-sm" name="new_status" style="width: 160px;" <?= $isSelf ? 'disabled' : '' ?>>
                        <option value="pending" <?= $status==='pending'?'selected':'' ?>>pending</option>
                        <option value="approved" <?= $status==='approved'?'selected':'' ?>>approved</option>
                        <option value="rejected" <?= $status==='rejected'?'selected':'' ?>>rejected</option>
                        <option value="suspended" <?= $status==='suspended'?'selected':'' ?>>suspended</option>
                      </select>
                      <button class="btn btn-sm btn-outline-light" type="submit" <?= $isSelf ? 'disabled' : '' ?>>Save</button>
                    </form>

                    <!-- Role -->
                    <form method="POST" class="d-inline-flex gap-2 align-items-center ms-2">
                      <input type="hidden" name="user_id" value="<?= $uid ?>">
                      <input type="hidden" name="action" value="set_role">
                      <select class="form-select form-select-sm" name="new_role" style="width: 150px;" <?= $isSelf ? 'disabled' : '' ?>>
                        <option value="user" <?= $role==='user'?'selected':'' ?>>user</option>
                        <option value="trainer" <?= $role==='trainer'?'selected':'' ?>>trainer</option>
                        <option value="admin" <?= $role==='admin'?'selected':'' ?>>admin</option>
                      </select>
                      <button class="btn btn-sm btn-outline-light" type="submit" <?= $isSelf ? 'disabled' : '' ?>>Save</button>
                    </form>

                    <!-- Unlink trainer -->
                    <?php if ($role === 'user' && $trainerId > 0): ?>
                      <form method="POST" class="d-inline ms-2"
                            onsubmit="return confirm('Unlink this trainee from their trainer?');">
                        <input type="hidden" name="user_id" value="<?= $uid ?>">
                        <input type="hidden" name="action" value="unlink_trainer">
                        <button class="btn btn-sm btn-outline-warning" type="submit" title="Unlink trainer">
                          <i class="fa-solid fa-link-slash"></i>
                        </button>
                      </form>
                    <?php endif; ?>

                    <!-- Delete -->
                    <form method="POST" class="d-inline-flex gap-2 align-items-center ms-2"
                          onsubmit="return confirm('Delete this user? Entered admin password will be used for confirmation. This may cascade delete related rows via FK rules.');">
                      <input type="hidden" name="user_id" value="<?= $uid ?>">
                      <input type="hidden" name="action" value="delete_user">
                      <input type="password"
                            name="admin_password"
                            class="form-control form-control-sm"
                            placeholder="Admin password"
                            style="width: 160px;"
                            <?= $isSelf ? 'disabled' : '' ?>
                            required>
                      <button class="btn btn-sm btn-outline-danger" type="submit" <?= $isSelf ? 'disabled' : '' ?> title="Delete user">
                        <i class="fa-solid fa-trash"></i>
                      </button>
                    </form>
                  </td>
                </tr>
              <?php endforeach; ?>
            <?php endif; ?>
            </tbody>

          </table>
        </div>
      </div>

      <div class="d-flex justify-content-between align-items-center p-3 border-top">
        <div class="lr-stat-subtext mb-0">
          Page <?= (int)$page ?> of <?= (int)$total_pages ?>
        </div>

        <nav aria-label="Users pagination">
          <ul class="pagination pagination-sm mb-0">
            <?php
              $prevDisabled = ($page <= 1) ? ' disabled' : '';
              $nextDisabled = ($page >= $total_pages) ? ' disabled' : '';

              $prevUrl = $BASE_URL . "/admin/users.php?" . build_query(['page' => max(1, $page - 1)]);
              $nextUrl = $BASE_URL . "/admin/users.php?" . build_query(['page' => min($total_pages, $page + 1)]);
            ?>
            <li class="page-item<?= $prevDisabled ?>">
              <a class="page-link" href="<?= $prevDisabled ? '#' : h($prevUrl) ?>">Prev</a>
            </li>

            <li class="page-item<?= $nextDisabled ?>">
              <a class="page-link" href="<?= $nextDisabled ? '#' : h($nextUrl) ?>">Next</a>
            </li>
          </ul>
        </nav>
      </div>

      <div class="lr-card-body">
        <div class="lr-stat-subtext mb-0">
          Notes: Status drives access (recommended). Role drives UI + permissions. For safety, you can't delete or downgrade your own account while logged in.
        </div>
      </div>

    </div>
  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>
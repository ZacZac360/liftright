<?php
// liftright/web/admin/users.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

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

      $stmt = $mysqli->prepare("UPDATE users SET role=? WHERE user_id=?");
      $stmt->bind_param("si", $new_role, $user_id);
      $stmt->execute();
      $stmt->close();

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

      $stmt = $mysqli->prepare("UPDATE users SET account_status=? WHERE user_id=?");
      $stmt->bind_param("si", $new_status, $user_id);
      $stmt->execute();
      $stmt->close();

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
      // only for trainees
      $stmt = $mysqli->prepare("UPDATE users SET trainer_id = NULL WHERE user_id=? AND role='user'");
      $stmt->bind_param("i", $user_id);
      $stmt->execute();
      $stmt->close();

      $flash = "Unlinked trainer successfully.";
      $flash_kind = 'success';
    }

    elseif ($action === 'delete_user') {
      if ($user_id === $self_id) {
        throw new Exception("You can't delete your own account while logged in.");
      }

      $stmt = $mysqli->prepare("DELETE FROM users WHERE user_id=?");
      $stmt->bind_param("i", $user_id);
      $stmt->execute();
      $stmt->close();

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
$q = trim((string)($_GET['q'] ?? ''));
$roleFilter = trim((string)($_GET['role'] ?? ''));
$statusFilter = trim((string)($_GET['status'] ?? ''));

$allowedRoles = ['user','trainer','admin'];
$allowedStatus = ['pending','approved','rejected','suspended'];

$users = [];

$sql = "
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
  FROM users u
  LEFT JOIN users t ON t.user_id = u.trainer_id
  WHERE u.role <> 'admin'
";
$types = "";
$params = [];

if ($q !== '') {
  $sql .= " AND (u.full_name LIKE CONCAT('%', ?, '%') OR u.email LIKE CONCAT('%', ?, '%') OR CAST(u.user_id AS CHAR) = ?)";
  $types .= "sss";
  $params[] = $q;
  $params[] = $q;
  $params[] = $q;
}
if (in_array($roleFilter, $allowedRoles, true)) {
  $sql .= " AND u.role = ?";
  $types .= "s";
  $params[] = $roleFilter;
}
if (in_array($statusFilter, $allowedStatus, true)) {
  $sql .= " AND u.account_status = ?";
  $types .= "s";
  $params[] = $statusFilter;
}

$sql .= " ORDER BY u.created_at DESC LIMIT 250";

$stmt = $mysqli->prepare($sql);
if ($types !== "") {
  $stmt->bind_param($types, ...$params);
}
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
          <div class="lr-section-heading mb-0">Users (max 250)</div>
        </div>
        <div class="lr-stat-subtext mb-0"><?= (int)count($users) ?> shown</div>
      </div>

      <div class="lr-card-body p-0">
        <div class="table-responsive">
          <table class="table table-hover table-striped align-middle mb-0 table-lr-dark">
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
                    <form method="POST" class="d-inline ms-2"
                          onsubmit="return confirm('Delete this user? This may cascade delete related rows via FK rules.');">
                      <input type="hidden" name="user_id" value="<?= $uid ?>">
                      <input type="hidden" name="action" value="delete_user">
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

      <div class="lr-card-body">
        <div class="lr-stat-subtext mb-0">
          Notes: Status drives access (recommended). Role drives UI + permissions. For safety, you can't delete or downgrade your own account while logged in.
        </div>
      </div>

    </div>
  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>
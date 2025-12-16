<?php
// liftright/web/admin/users.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['admin']);

$page_title = "Manage Users";

$flash = null;

// Handle actions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $action = (string)($_POST['action'] ?? '');
  $user_id = (int)($_POST['user_id'] ?? 0);

  try {
    if ($action === 'set_role') {
      $new_role = (string)($_POST['new_role'] ?? 'user');
      if (!in_array($new_role, ['user','trainer','admin'], true)) {
        throw new Exception("Invalid role.");
      }

      // prevent admin from demoting/deleting themselves accidentally? allow but guard lightly
      $stmt = $mysqli->prepare("UPDATE users SET role=? WHERE user_id=?");
      $stmt->bind_param("si", $new_role, $user_id);
      $stmt->execute();
      $stmt->close();

      $flash = "Updated user role successfully.";
    }

    if ($action === 'delete_user') {
      if ($user_id <= 0) throw new Exception("Invalid user.");
      if ($user_id === (int)($_SESSION['user_id'] ?? 0)) {
        throw new Exception("You can't delete your own account while logged in.");
      }

      $stmt = $mysqli->prepare("DELETE FROM users WHERE user_id=?");
      $stmt->bind_param("i", $user_id);
      $stmt->execute();
      $stmt->close();

      $flash = "Deleted user successfully.";
    }
  } catch (Throwable $e) {
    $flash = "Error: " . $e->getMessage();
  }
}

$q = trim((string)($_GET['q'] ?? ''));
$roleFilter = trim((string)($_GET['role'] ?? ''));

$users = [];

$sql = "
  SELECT user_id, full_name, email, role, created_at, last_login
  FROM users
  WHERE 1=1
";
$types = "";
$params = [];

if ($q !== '') {
  $sql .= " AND (full_name LIKE CONCAT('%', ?, '%') OR email LIKE CONCAT('%', ?, '%'))";
  $types .= "ss";
  $params[] = $q;
  $params[] = $q;
}
if (in_array($roleFilter, ['user','trainer','admin'], true)) {
  $sql .= " AND role = ?";
  $types .= "s";
  $params[] = $roleFilter;
}

$sql .= " ORDER BY created_at DESC LIMIT 200";

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
        <p class="lr-stat-subtext mb-0">Edit roles, audit logins, and remove accounts (prototype).</p>
      </div>
    </div>

    <?php if ($flash): ?>
      <div class="alert alert-dark border border-secondary"><?= h($flash) ?></div>
    <?php endif; ?>

    <div class="lr-card mb-3">
      <div class="lr-card-body">
        <form class="row g-2" method="GET" action="">
          <div class="col-md-6">
            <input class="form-control" name="q" value="<?= h($q) ?>" placeholder="Search name or email...">
          </div>
          <div class="col-md-3">
            <select class="form-select" name="role">
              <option value="">All roles</option>
              <option value="user" <?= $roleFilter==='user'?'selected':'' ?>>user (trainee)</option>
              <option value="trainer" <?= $roleFilter==='trainer'?'selected':'' ?>>trainer (coach)</option>
              <option value="admin" <?= $roleFilter==='admin'?'selected':'' ?>>admin</option>
            </select>
          </div>
          <div class="col-md-3 d-grid">
            <button class="btn btn-primary" type="submit">
              <i class="fa-solid fa-magnifying-glass me-2"></i>Filter
            </button>
          </div>
        </form>
      </div>
    </div>

    <div class="lr-card">
      <div class="lr-card-header">
        <div class="lr-section-title mb-1">Accounts</div>
        <div class="lr-section-heading mb-0">Users (max 200)</div>
      </div>

      <div class="lr-card-body p-0">
        <div class="table-responsive">
          <table class="table table-hover table-striped align-middle mb-0 table-lr-dark">
            <thead>
              <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Role</th>
                <th>Created</th>
                <th>Last login</th>
                <th class="text-end">Actions</th>
              </tr>
            </thead>
            <tbody>
            <?php if (count($users) === 0): ?>
              <tr><td colspan="6" class="text-center py-4 lr-stat-subtext">No users found.</td></tr>
            <?php else: ?>
              <?php foreach ($users as $u): ?>
                <tr>
                  <td><?= h((string)$u['full_name']) ?></td>
                  <td><?= h((string)$u['email']) ?></td>
                  <td><span class="lr-chip-exercise"><?= h((string)$u['role']) ?></span></td>
                  <td><?= h(date("M d, Y", strtotime((string)$u['created_at']))) ?></td>
                  <td><?= $u['last_login'] ? h(date("M d, Y • g:i A", strtotime((string)$u['last_login']))) : '—' ?></td>
                  <td class="text-end">
                    <form method="POST" class="d-inline-flex gap-2 align-items-center">
                      <input type="hidden" name="user_id" value="<?= (int)$u['user_id'] ?>">
                      <input type="hidden" name="action" value="set_role">
                      <select class="form-select form-select-sm" name="new_role" style="width: 150px;">
                        <option value="user" <?= $u['role']==='user'?'selected':'' ?>>user</option>
                        <option value="trainer" <?= $u['role']==='trainer'?'selected':'' ?>>trainer</option>
                        <option value="admin" <?= $u['role']==='admin'?'selected':'' ?>>admin</option>
                      </select>
                      <button class="btn btn-sm btn-outline-light" type="submit">Save</button>
                    </form>

                    <form method="POST" class="d-inline ms-2" onsubmit="return confirm('Delete this user? This will also delete related logs via FK cascades.');">
                      <input type="hidden" name="user_id" value="<?= (int)$u['user_id'] ?>">
                      <input type="hidden" name="action" value="delete_user">
                      <button class="btn btn-sm btn-outline-danger" type="submit">
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

    </div>
  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>

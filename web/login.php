<?php
session_start();
require_once __DIR__ . "/config/config.php";

$page_title = "Login";

$err = "";
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $email = trim((string)($_POST['email'] ?? ''));
  $pass  = (string)($_POST['password'] ?? '');

  if ($email === "" || $pass === "") {
    $err = "Enter your email and password.";
  } else {
    $stmt = $mysqli->prepare("SELECT user_id, full_name, email, password_hash, role FROM users WHERE email = ? LIMIT 1");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $res = $stmt->get_result();
    $u = $res->fetch_assoc();
    $stmt->close();

    if (!$u || !password_verify($pass, (string)$u['password_hash'])) {
      $err = "Invalid credentials.";
    } else {
      $_SESSION['user_id']   = (int)$u['user_id'];
      $_SESSION['full_name'] = (string)$u['full_name'];
      $_SESSION['email']     = (string)$u['email'];
      $_SESSION['role']      = (string)$u['role'];

      $uid = (int)$u['user_id'];
      $mysqli->query("UPDATE users SET last_login = NOW() WHERE user_id = {$uid}");

      // Direct route by DB role (user/trainer/admin)
      $role = (string)$u['role'];
      if ($role === 'user') {
        header("Location: {$BASE_URL}/trainee/dashboard.php");
        exit;
      }
      if ($role === 'trainer') {
        header("Location: {$BASE_URL}/coach/dashboard.php");
        exit;
      }
      if ($role === 'admin') {
        header("Location: {$BASE_URL}/admin/dashboard.php");
        exit;
      }

      // fallback
      header("Location: {$BASE_URL}/logout.php");
      exit;
    }
  }
}

require __DIR__ . "/includes/head.php";
?>
<body>
<div class="lr-auth-wrapper">
  <div class="lr-auth-card">
    <div class="lr-auth-brand mb-2">LiftRight</div>
    <div class="lr-auth-heading mb-1">Sign in</div>
    <div class="lr-auth-subtext mb-3">Use your prototype account.</div>

    <?php if ($err): ?>
      <div class="alert alert-danger"><?= h($err) ?></div>
    <?php endif; ?>

    <form method="post" class="d-grid gap-2">
      <div>
        <label class="form-label">Email</label>
        <input name="email" type="email" class="form-control" required value="<?= h($_POST['email'] ?? '') ?>">
      </div>
      <div>
        <label class="form-label">Password</label>
        <input name="password" type="password" class="form-control" required>
      </div>

      <button class="btn btn-primary mt-2">Login</button>

      <!-- Register disabled for now -->
      <button class="btn btn-outline-light" type="button" disabled title="Register is disabled for now">
        Create account (disabled)
      </button>
    </form>
  </div>
</div>
</body>
</html>

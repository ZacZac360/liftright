<?php
session_start();
require_once __DIR__ . "/config/config.php";

$page_title = "Register";

$err = "";
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $full_name = trim((string)($_POST['full_name'] ?? ''));
  $email     = trim((string)($_POST['email'] ?? ''));
  $age       = trim((string)($_POST['age'] ?? ''));
  $pass      = (string)($_POST['password'] ?? '');
  $pass2     = (string)($_POST['password2'] ?? '');

  if ($full_name === "" || $email === "" || $pass === "") {
    $err = "Please fill in all required fields.";
  } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    $err = "Invalid email address.";
  } elseif ($pass !== $pass2) {
    $err = "Passwords do not match.";
  } elseif (strlen($pass) < 8) {
    $err = "Password must be at least 8 characters.";
  } else {
    $ageInt = ($age === "") ? null : (int)$age;
    $hash = password_hash($pass, PASSWORD_BCRYPT);

    try {
      $stmt = $mysqli->prepare("INSERT INTO users (full_name, email, password_hash, role, age) VALUES (?, ?, ?, 'user', ?)");
      // bind age as int or null
      if ($ageInt === null) {
        $stmt->bind_param("sssi", $full_name, $email, $hash, $ageInt); // will still pass 0 if null, so do manual:
        $stmt->close();
        $stmt = $mysqli->prepare("INSERT INTO users (full_name, email, password_hash, role, age) VALUES (?, ?, ?, 'user', NULL)");
        $stmt->bind_param("sss", $full_name, $email, $hash);
      } else {
        $stmt->bind_param("sssi", $full_name, $email, $hash, $ageInt);
      }
      $stmt->execute();

      header("Location: {$BASE_URL}/login.php?registered=1");
      exit;
    } catch (mysqli_sql_exception $e) {
      // duplicate email
      $err = "That email is already registered.";
    }
  }
}

require __DIR__ . "/includes/head.php";
?>
<body>
<div class="lr-auth-wrapper">
  <div class="lr-auth-card">
    <div class="lr-auth-brand mb-2">LiftRight</div>
    <div class="lr-auth-heading mb-1">Create account</div>
    <div class="lr-auth-subtext mb-3">Prototype access (XAMPP)</div>

    <?php if ($err): ?>
      <div class="alert alert-danger"><?= h($err) ?></div>
    <?php endif; ?>

    <form method="post" class="d-grid gap-2">
      <div>
        <label class="form-label">Full name</label>
        <input name="full_name" class="form-control" required value="<?= h($_POST['full_name'] ?? '') ?>">
      </div>
      <div>
        <label class="form-label">Email</label>
        <input name="email" type="email" class="form-control" required value="<?= h($_POST['email'] ?? '') ?>">
      </div>
      <div>
        <label class="form-label">Age (optional)</label>
        <input name="age" type="number" class="form-control" min="1" max="120" value="<?= h($_POST['age'] ?? '') ?>">
      </div>
      <div>
        <label class="form-label">Password</label>
        <input name="password" type="password" class="form-control" required>
      </div>
      <div>
        <label class="form-label">Confirm password</label>
        <input name="password2" type="password" class="form-control" required>
      </div>

      <button class="btn btn-primary mt-2">Create account</button>
      <a class="btn btn-outline-light" href="<?= $BASE_URL ?>/login.php">Back to login</a>
    </form>
  </div>
</div>
</body>
</html>

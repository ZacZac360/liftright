<?php
// login.php - simple login screen

session_start();
require_once __DIR__ . '/config/config.php';

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email    = trim($_POST['email'] ?? '');
    $password = trim($_POST['password'] ?? '');

    if ($email === '' || $password === '') {
        $error = 'Please enter both email and password.';
    } else {
        $stmt = $mysqli->prepare("SELECT id, full_name, role, password FROM users WHERE email = ?");
        $stmt->bind_param("s", $email);
        $stmt->execute();
        $result = $stmt->get_result();
        $user   = $result->fetch_assoc();
        $stmt->close();

        if ($user && $password === $user['password']) {
            // NOTE: plain-text for now; later replace with password_verify
            $_SESSION['user_id']   = $user['id'];
            $_SESSION['full_name'] = $user['full_name'];
            $_SESSION['role']      = $user['role'];

            // Redirect based on role
            if ($user['role'] === 'trainee') {
                header("Location: {$BASE_URL}/trainee/dashboard.php");
            } elseif ($user['role'] === 'coach') {
                header("Location: {$BASE_URL}/coach/dashboard.php");
            } else {
                header("Location: {$BASE_URL}/admin/dashboard.php");
            }
            exit;
        } else {
            $error = 'Invalid email or password.';
        }
    }
}
?>

<?php require __DIR__ . '/includes/head.php'; ?>
<body>
<div class="lr-auth-wrapper">
    <div class="lr-auth-card">
        <div class="mb-3 text-center">
            <div class="lr-auth-brand mb-1">LIFTRIGHT</div>
            <div class="lr-auth-heading">Sign in to continue</div>
            <p class="lr-auth-subtext mb-0">
                Use the demo account: <strong>trainee@example.com / password123</strong>
            </p>
        </div>

        <?php if ($error): ?>
            <div class="alert alert-danger py-2">
                <?php echo htmlspecialchars($error); ?>
            </div>
        <?php endif; ?>

        <form method="post" novalidate>
            <div class="mb-3">
                <label class="form-label text-light">Email</label>
                <input type="email" name="email" class="form-control bg-dark text-light border-secondary"
                       placeholder="you@example.com" required>
            </div>
            <div class="mb-3">
                <label class="form-label text-light">Password</label>
                <input type="password" name="password" class="form-control bg-dark text-light border-secondary"
                       placeholder="••••••••" required>
            </div>

            <button type="submit" class="btn btn-primary w-100 mt-2">
                Sign in
            </button>
        </form>

        <p class="lr-auth-subtext text-center mt-3 mb-0">
            Prototype build – real AI posture &amp; fatigue metrics integrate later.
        </p>
    </div>
</div>

<?php require __DIR__ . '/includes/footer.php'; ?>

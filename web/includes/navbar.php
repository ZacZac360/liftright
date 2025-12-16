<?php
// liftright/web/includes/navbar.php
global $BASE_URL;

$role = $_SESSION['role'] ?? null;
$full_name = $_SESSION['full_name'] ?? null;

function initials(string $name): string {
  $parts = preg_split('/\s+/', trim($name));
  $a = $parts[0][0] ?? 'U';
  $b = $parts[count($parts)-1][0] ?? '';
  return strtoupper($a . $b);
}
?>
<nav class="navbar navbar-expand-lg navbar-dark fixed-top liftright-navbar">
  <div class="container">
    <a class="navbar-brand d-flex flex-column" href="<?= $BASE_URL ?>/index.php">
      <span class="brand-accent">LiftRight</span>
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
            <li class="nav-item"><a class="nav-link" href="<?= $BASE_URL ?>/trainee/dashboard.php">Dashboard</a></li>
            <li class="nav-item"><a class="nav-link" href="<?= $BASE_URL ?>/trainee/sessions.php">Sessions</a></li>
            <li class="nav-item"><a class="nav-link" href="<?= $BASE_URL ?>/trainee/sus.php">SUS</a></li> 
            <li class="nav-item"><a class="nav-link" href="<?= $BASE_URL ?>/trainee/profile.php">Profile</a></li>         
            <?php elseif ($role === 'trainer'): ?>
            <li class="nav-item"><a class="nav-link" href="<?= $BASE_URL ?>/coach/dashboard.php">Coach</a></li>
          <?php elseif ($role === 'admin'): ?>
            <li class="nav-item"><a class="nav-link" href="<?= $BASE_URL ?>/admin/dashboard.php">Admin</a></li>
            <li class="nav-item"><a class="nav-link" href="<?= $BASE_URL ?>/admin/thresholds.php">Thresholds</a></li>
          <?php endif; ?>

          <li class="nav-item d-flex align-items-center gap-2 ms-lg-3">
            <div class="avatar-circle"><?= h(initials((string)$full_name)) ?></div>
            <div class="d-none d-lg-block small">
              <div class="fw-semibold"><?= h((string)$full_name) ?></div>
              <div class="text-secondary" style="opacity:.85;"><?= h((string)$role) ?></div>
            </div>
          </li>
          <li class="nav-item"><a class="nav-link" href="<?= $BASE_URL ?>/logout.php">Logout</a></li>
        <?php endif; ?>
      </ul>
    </div>
  </div>
</nav>

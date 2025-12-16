<?php
// includes/navbar.php - top navigation bar (simple, role-aware later)

$current_role = $_SESSION['role'] ?? null;
$current_name = $_SESSION['full_name'] ?? 'Guest';
?>
<nav class="navbar navbar-expand-lg navbar-dark liftright-navbar">
    <div class="container-fluid px-3 px-md-4">
        <a class="navbar-brand d-flex align-items-center gap-2" href="<?php echo $BASE_URL; ?>/index.php">
            <span class="brand-accent">LIFTRIGHT</span>
            <span class="brand-subtitle d-none d-sm-inline">Posture & Fatigue Monitor</span>
        </a>

        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#mainNav">
            <span class="navbar-toggler-icon"></span>
        </button>

        <div class="collapse navbar-collapse justify-content-end" id="mainNav">
            <ul class="navbar-nav mb-2 mb-lg-0 align-items-lg-center">
                <?php if ($current_role === 'trainee'): ?>
                    <li class="nav-item me-2">
                        <a class="nav-link" href="<?php echo $BASE_URL; ?>/trainee/dashboard.php">Dashboard</a>
                    </li>
                    <li class="nav-item me-2">
                        <a class="nav-link" href="<?php echo $BASE_URL; ?>/trainee/sessions.php">My Sessions</a>
                    </li>
                <?php elseif ($current_role === 'coach'): ?>
                    <li class="nav-item me-2">
                        <a class="nav-link" href="<?php echo $BASE_URL; ?>/coach/dashboard.php">Coach Dashboard</a>
                    </li>
                <?php elseif ($current_role === 'admin'): ?>
                    <li class="nav-item me-2">
                        <a class="nav-link" href="<?php echo $BASE_URL; ?>/admin/dashboard.php">Admin</a>
                    </li>
                <?php endif; ?>

                <?php if ($current_role): ?>
                    <li class="nav-item dropdown ms-lg-3">
                        <a class="nav-link dropdown-toggle d-flex align-items-center gap-2" href="#" role="button"
                           data-bs-toggle="dropdown">
                            <div class="avatar-circle">
                                <?php echo strtoupper(substr($current_name, 0, 1)); ?>
                            </div>
                            <span class="d-none d-sm-inline">
                                <?php echo htmlspecialchars($current_name); ?>
                            </span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end">
                            <li><a class="dropdown-item" href="#">Profile (coming soon)</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="<?php echo $BASE_URL; ?>/logout.php">Logout</a></li>
                        </ul>
                    </li>
                <?php else: ?>
                    <li class="nav-item ms-lg-3">
                        <a class="btn btn-outline-light btn-sm" href="<?php echo $BASE_URL; ?>/login.php">Login</a>
                    </li>
                <?php endif; ?>
            </ul>
        </div>
    </div>
</nav>

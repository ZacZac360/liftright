<?php
session_start();
require_once __DIR__ . "/config/config.php";

$role = $_SESSION['role'] ?? null;

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

if ($role && !in_array($role, ['user', 'trainer', 'admin'], true)) {
  header("Location: {$BASE_URL}/logout.php");
  exit;
}

$logoPath = $BASE_URL . "/assets/images/logo/liftright-logo.png";
$heroPath = $BASE_URL . "/assets/images/landing/hero-athlete.png";
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>LiftRight</title>
  <meta name="description" content="Real-time posture feedback and fatigue-aware monitoring for weightlifting.">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="<?= $BASE_URL ?>/assets/css/landing.css">
  <link rel="icon" type="image/x-icon" href="/liftright/web/favicon.ico">
</head>
<body class="lr-landing-body">

  <main class="lr-landing">
    <div class="lr-landing__bg"></div>
    <div class="lr-landing__glow lr-landing__glow--left"></div>
    <div class="lr-landing__glow lr-landing__glow--right"></div>

    <section class="lr-hero">
      <div class="lr-hero__content">

        <a href="<?= $BASE_URL ?>/index.php" class="lr-brand" aria-label="LiftRight home">
          <span class="lr-brand__logo-wrap">
            <img
              src="<?= htmlspecialchars($logoPath) ?>"
              alt="LiftRight logo"
              class="lr-brand__logo"
              onerror="this.style.display='none'; this.parentNode.classList.add('is-empty');"
            >
          </span>
          <span class="lr-brand__text">LiftRight</span>
        </a>

        <div class="lr-copy">
          <h1 class="lr-copy__title">
            Train Smarter<br>
            With LiftRight
          </h1>

          <p class="lr-copy__subtitle">
            Real-time posture feedback and fatigue-aware monitoring
            for weightlifting.
          </p>

          <div class="lr-copy__actions">
            <a href="<?= $BASE_URL ?>/login.php" class="lr-btn lr-btn--primary">Get Started</a>
            <a href="<?= $BASE_URL ?>/login.php" class="lr-btn lr-btn--ghost">Log In</a>
          </div>
        </div>
      </div>

      <div class="lr-hero__visual" aria-hidden="true">
        <div class="lr-hero__image-wrap">
          <img
            src="<?= htmlspecialchars($heroPath) ?>"
            alt=""
            class="lr-hero__image"
            onerror="this.style.display='none'; this.parentNode.classList.add('is-empty');"
          >
        </div>
      </div>
    </section>

    <div class="lr-attribution">
      <a
        href="https://www.vecteezy.com/free-png/bicep-curl"
        target="_blank"
        rel="noopener"
      >
        Bicep Curl PNGs by Vecteezy
      </a>
    </div>
  </main>

</body>
</html>
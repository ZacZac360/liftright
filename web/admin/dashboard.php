<?php
session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['admin']);

$page_title = "Admin Dashboard";

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="lr-page-wrapper">
  <div class="container lr-main-container py-4">
    <div class="lr-card">
      <div class="lr-card-header">
        <div class="lr-section-title mb-1">Admin</div>
        <div class="lr-section-heading mb-0">Dashboard (Coming Soon)</div>
      </div>
      <div class="lr-card-body">
        <p class="lr-stat-subtext mb-0">
          Admin controls (threshold tuning) will be built next. Trainee flow first.
        </p>
      </div>
    </div>
  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>

<?php
session_start();
require_once __DIR__ . "/config/config.php";
require_once __DIR__ . "/config/auth.php";

$page_title = "Forgot Password";

if (!function_exists('h')) {
  function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
}

require __DIR__ . "/includes/head.php";
?>
<body>
<div class="lr-auth-wrapper">
  <div class="lr-auth-card" style="max-width: 520px;">
    <div class="lr-auth-brand mb-2">LiftRight</div>
    <div class="lr-auth-heading mb-1">Forgot your password?</div>
    <div class="lr-auth-subtext mb-3">
      Enter your email and we’ll send a password reset link.
    </div>

    <div id="alertOk" class="alert alert-success" style="display:none;"></div>
    <div id="alertErr" class="alert alert-danger" style="display:none;"></div>
    <div id="alertDev" class="alert alert-warning" style="display:none;"></div>

    <form class="d-grid gap-2" id="forgotForm">
      <label class="form-label">Email</label>
      <input name="email" id="emailInput" type="email" class="form-control" placeholder="you@example.com" required>
      <button class="btn btn-primary mt-2" id="btnSubmit" type="submit">Send reset link</button>
    </form>

    <div class="mt-3 text-center">
      <a class="lr-link" href="<?= $BASE_URL ?>/login.php">Back to login</a>
    </div>
  </div>
</div>

<script>
  const BASE_URL = <?= json_encode($BASE_URL) ?>;

  const okBox  = document.getElementById('alertOk');
  const errBox = document.getElementById('alertErr');
  const devBox = document.getElementById('alertDev');
  const form = document.getElementById('forgotForm');
  const btn = document.getElementById('btnSubmit');
  const emailInput = document.getElementById('emailInput');

  function show(box, msg){
    [okBox, errBox, devBox].forEach(b => { b.style.display = 'none'; b.textContent = ''; });
    box.textContent = msg || '';
    box.style.display = 'block';
  }

  form.addEventListener('submit', async (e) => {
    e.preventDefault();

    const fd = new FormData();
    fd.append('email', emailInput.value || '');

    btn.disabled = true;
    btn.textContent = 'Sending...';

    const res = await fetch(BASE_URL + '/api/forgot-password.php', {
      method: 'POST',
      body: fd,
      credentials: 'same-origin'
    });

    let data = {};
    try { data = await res.json(); } catch (e) {}

    btn.disabled = false;
    btn.textContent = 'Send reset link';

    if (data.success) {
      show(okBox, data.message || 'If the email exists, a reset link has been sent.');
      if (data.dev_reset_url) show(devBox, 'DEV RESET LINK: ' + data.dev_reset_url);
    } else {
      show(errBox, data.message || 'Request failed.');
    }
  });
</script>
</body>
</html>
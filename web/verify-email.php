<?php
session_start();
require_once __DIR__ . "/config/config.php";
require_once __DIR__ . "/config/auth.php";

$page_title = "Verify Email";

if (!function_exists('h')) {
  function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
}

$pending_id = (int)($_SESSION['pre_verify_pending_id'] ?? 0);
if ($pending_id <= 0) {
  header("Location: {$BASE_URL}/login.php");
  exit;
}

// load pending user
$stmt = $mysqli->prepare("SELECT full_name, email FROM pending_registrations WHERE pending_id=? LIMIT 1");
$stmt->bind_param("i", $pending_id);
$stmt->execute();
$u = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$u) {
  unset($_SESSION['pre_verify_pending_id'], $_SESSION['dev_verify_otp']);
  header("Location: {$BASE_URL}/login.php");
  exit;
}

require __DIR__ . "/includes/head.php";
?>
<body>
<div class="lr-auth-wrapper">
  <div class="lr-auth-card" style="max-width: 520px;">
    <div class="lr-auth-brand mb-2">LiftRight</div>
    <div class="lr-auth-heading mb-1">Verify your email</div>
    <div class="lr-auth-subtext mb-3">
      We’ll verify <b><?= h((string)$u['email']) ?></b> with a 6-digit code.
    </div>

    <div id="alertOk" class="alert alert-success" style="display:none;"></div>
    <div id="alertErr" class="alert alert-danger" style="display:none;"></div>
    <div id="alertDev" class="alert alert-warning" style="display:none;"></div>

    <form class="d-grid gap-2" id="verifyForm">
      <label class="form-label">Verification code</label>
      <input name="otp" id="otpInput" class="form-control text-center" inputmode="numeric" maxlength="6"
             placeholder="123456" required>
      <button class="btn btn-primary mt-2" id="btnVerify" type="submit">Verify</button>
    </form>

    <button class="btn btn-outline-light w-100 mt-3" id="btnResend" type="button">
      Send / Resend code
    </button>

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

  const btnResend = document.getElementById('btnResend');
  const btnVerify = document.getElementById('btnVerify');
  const otpInput  = document.getElementById('otpInput');
  const form      = document.getElementById('verifyForm');

  function show(box, msg){
    [okBox, errBox, devBox].forEach(b => { b.style.display = 'none'; b.textContent = ''; });
    box.textContent = msg || '';
    box.style.display = 'block';
  }

  async function postForm(url, dataObj){
    const fd = new FormData();
    Object.entries(dataObj || {}).forEach(([k,v]) => fd.append(k, v));

    const res = await fetch(url, { method: 'POST', body: fd, credentials: 'same-origin' });
    let data = {};
    try { data = await res.json(); } catch(e) {}
    if (!res.ok && !data.message) data.message = 'Request failed.';
    return data;
  }

  async function resend(){
    btnResend.disabled = true;
    btnResend.textContent = 'Sending...';

    const data = await postForm(BASE_URL + '/api/resend-email-otp.php', {});

    btnResend.disabled = false;
    btnResend.textContent = 'Send / Resend code';

    if (data.success) {
      show(okBox, data.message || 'OTP sent.');
      if (data.dev_otp) show(devBox, 'DEV OTP: ' + data.dev_otp);
    } else {
      show(errBox, data.message || 'Failed to send code.');
    }
  }

  form.addEventListener('submit', async (e) => {
    e.preventDefault();

    const code = (otpInput.value || '').replace(/\D+/g,'').slice(0,6);
    if (code.length !== 6) {
      show(errBox, 'Enter the 6-digit code.');
      return;
    }

    btnVerify.disabled = true;
    btnVerify.textContent = 'Verifying...';

    const data = await postForm(BASE_URL + '/api/verify-email-otp.php', { otp: code });

    btnVerify.disabled = false;
    btnVerify.textContent = 'Verify';

    if (data.success) {
      show(okBox, 'Verified! Redirecting...');
      window.location.href = BASE_URL + '/login.php?status=pending';
    } else {
      show(errBox, data.message || 'Verification failed.');
    }
  });

  // auto-send on load
  resend();
</script>
</body>
</html>
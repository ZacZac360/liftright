<?php
session_start();
require_once __DIR__ . "/config/config.php";
require_once __DIR__ . "/config/auth.php";

$page_title = "Reset Password";

if (!function_exists('h')) {
  function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
}

$user_id = (int)($_GET['u'] ?? 0);
$token   = trim((string)($_GET['token'] ?? ''));

if ($user_id <= 0 || $token === '') {
  header("Location: {$BASE_URL}/login.php?ok=" . urlencode("Invalid reset link."));
  exit;
}

require __DIR__ . "/includes/head.php";
?>
<body>
<div class="lr-auth-wrapper">
  <div class="lr-auth-card" style="max-width: 520px;">
    <div class="lr-auth-brand mb-2">LiftRight</div>
    <div class="lr-auth-heading mb-1">Reset your password</div>
    <div class="lr-auth-subtext mb-3">
      Enter your new password below.
    </div>

    <div id="alertOk" class="alert alert-success" style="display:none;"></div>
    <div id="alertErr" class="alert alert-danger" style="display:none;"></div>

    <form class="d-grid gap-2" id="resetForm">
      <input type="hidden" id="userId" value="<?= (int)$user_id ?>">
      <input type="hidden" id="token" value="<?= h($token) ?>">

      <div class="lr-pass-row">
        <label class="form-label">New password</label>
        <input id="pass1" type="password" class="form-control" placeholder="At least 8 characters" required>
      </div>

      <div class="mt-2 lr-meter"><div id="passBar"></div></div>

      <ul class="lr-req" id="passReq">
        <li class="bad" data-req="len">At least 8 characters</li>
        <li class="bad" data-req="low">Lowercase letter</li>
        <li class="bad" data-req="up">Uppercase letter</li>
        <li class="bad" data-req="num">Number</li>
        <li class="bad" data-req="sym">Special character (!@#$...)</li>
      </ul>

      <div class="lr-pass-row">
        <label class="form-label">Confirm password</label>
        <input id="pass2" type="password" class="form-control" placeholder="Repeat password" required>
        <div class="form-text text-muted" id="matchText"></div>
      </div>

      <button class="btn btn-primary mt-2" id="btnSubmit" type="submit" disabled>Reset password</button>
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
  const form = document.getElementById('resetForm');
  const btn = document.getElementById('btnSubmit');
  const pass1 = document.getElementById('pass1');
  const pass2 = document.getElementById('pass2');
  const userId = document.getElementById('userId');
  const token = document.getElementById('token');
  const bar = document.getElementById('passBar');
  const reqList = document.getElementById('passReq');
  const matchText = document.getElementById('matchText');

  function show(box, msg){
    [okBox, errBox].forEach(b => { b.style.display = 'none'; b.textContent = ''; });
    box.textContent = msg || '';
    box.style.display = 'block';
  }

  function setReq(key, ok){
    const li = reqList.querySelector(`[data-req="${key}"]`);
    if (!li) return;
    li.classList.toggle('ok', ok);
    li.classList.toggle('bad', !ok);
  }

  function validatePassword(p){
    return {
      len: p.length >= 8,
      low: /[a-z]/.test(p),
      up:  /[A-Z]/.test(p),
      num: /\d/.test(p),
      sym: /[^A-Za-z0-9]/.test(p),
    };
  }

  function score(rules){
    let s = 0;
    Object.values(rules).forEach(v => { if (v) s++; });
    return s;
  }

  function syncPasswordUI(){
    const p = pass1.value || '';
    const rules = validatePassword(p);

    setReq('len', rules.len);
    setReq('low', rules.low);
    setReq('up',  rules.up);
    setReq('num', rules.num);
    setReq('sym', rules.sym);

    const s = score(rules);
    if (bar) bar.style.width = ((s/5)*100) + '%';

    const match = (pass2.value || '') !== '' && pass2.value === p;
    if ((pass2.value || '') === '') {
      matchText.textContent = '';
    } else {
      matchText.textContent = match ? 'Passwords match.' : 'Passwords do not match.';
      matchText.style.color = match ? 'rgba(59,230,120,.95)' : 'rgba(255,122,122,.95)';
    }

    btn.disabled = !((s === 5) && match);
  }

  pass1.addEventListener('input', syncPasswordUI);
  pass2.addEventListener('input', syncPasswordUI);
  syncPasswordUI();

  form.addEventListener('submit', async (e) => {
    e.preventDefault();

    const fd = new FormData();
    fd.append('user_id', userId.value);
    fd.append('token', token.value);
    fd.append('password', pass1.value);
    fd.append('password2', pass2.value);

    btn.disabled = true;
    btn.textContent = 'Resetting...';

    const res = await fetch(BASE_URL + '/api/reset-password.php', {
      method: 'POST',
      body: fd,
      credentials: 'same-origin'
    });

    let data = {};
    try { data = await res.json(); } catch (e) {}

    btn.disabled = false;
    btn.textContent = 'Reset password';

    if (data.success) {
      show(okBox, data.message || 'Password updated. Redirecting...');
      window.location.href = data.redirect || (BASE_URL + '/login.php');
    } else {
      show(errBox, data.message || 'Reset failed.');
    }
  });
</script>
</body>
</html>
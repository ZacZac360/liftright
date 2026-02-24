<?php
session_start();
require_once __DIR__ . "/config/config.php";
require_once __DIR__ . "/config/auth.php";

$page_title = "Login / Register";

if (!function_exists('h')) {
  function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
}

$err = "";
$ok  = "";

/* ---------- Status messages (account_status UX) ---------- */
$statusMsg = "";
if (isset($_GET['status'])) {
  $s = (string)$_GET['status'];
  if ($s === 'pending')       $statusMsg = "Your account is awaiting admin approval.";
  elseif ($s === 'rejected')  $statusMsg = "Your account was rejected. Please contact the administrator.";
  elseif ($s === 'suspended') $statusMsg = "Your account has been suspended.";
}

/* ---------- Helpers ---------- */

/**
 * Email verification OTP for pending registrations (email_verifications.pending_id).
 * Consumes old unused codes so only ONE is valid.
 */
function create_pending_email_verification(mysqli $db, int $pending_id, int $ttl_seconds = 900): string {
  $stmt = $db->prepare("
    UPDATE email_verifications
    SET consumed_at = NOW()
    WHERE pending_id = ? AND consumed_at IS NULL
  ");
  $stmt->bind_param("i", $pending_id);
  $stmt->execute();
  $stmt->close();

  $code = str_pad((string)random_int(0, 999999), 6, '0', STR_PAD_LEFT);
  $hash = password_hash($code, PASSWORD_DEFAULT);

  $stmt = $db->prepare("
    INSERT INTO email_verifications (pending_id, token_hash, expires_at)
    VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? SECOND))
  ");
  $stmt->bind_param("isi", $pending_id, $hash, $ttl_seconds);
  $stmt->execute();
  $stmt->close();

  return $code;
}

function is_locked(array $u): bool {
  if (empty($u['lock_until'])) return false;
  return strtotime((string)$u['lock_until']) > time();
}

function ext_from_mime(string $mime): ?string {
  return match (strtolower($mime)) {
    'application/pdf' => 'pdf',
    'image/jpeg'      => 'jpg',
    'image/png'       => 'png',
    default           => null
  };
}

function brevo_send_email(string $toEmail, string $toName, string $subject, string $html): bool {
  if (!defined('BREVO_API_KEY') || !BREVO_API_KEY) return false;
  if (!defined('BREVO_SENDER_EMAIL') || !BREVO_SENDER_EMAIL) return false;

  $payload = [
    "sender" => [
      "email" => BREVO_SENDER_EMAIL,
      "name"  => defined('BREVO_SENDER_NAME') ? BREVO_SENDER_NAME : "LiftRight"
    ],
    "to" => [[ "email" => $toEmail, "name" => $toName ]],
    "subject" => $subject,
    "htmlContent" => $html
  ];

  $ch = curl_init("https://api.brevo.com/v3/smtp/email");
  curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST => true,
    CURLOPT_HTTPHEADER => [
      "accept: application/json",
      "content-type: application/json",
      "api-key: " . BREVO_API_KEY,
    ],
    CURLOPT_POSTFIELDS => json_encode($payload),
    CURLOPT_TIMEOUT => 10,
  ]);

  $resp = curl_exec($ch);
  $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
  curl_close($ch);

  return ($resp !== false && $code >= 200 && $code < 300);
}

/**
 * Email verification OTP (email_verifications table).
 * Consumes old unused codes so only ONE is valid.
 */
function create_email_verification(mysqli $db, int $user_id, int $ttl_seconds = 900): string {
  $stmt = $db->prepare("
    UPDATE email_verifications
    SET consumed_at = NOW()
    WHERE user_id = ? AND consumed_at IS NULL
  ");
  $stmt->bind_param("i", $user_id);
  $stmt->execute();
  $stmt->close();

  $code = str_pad((string)random_int(0, 999999), 6, '0', STR_PAD_LEFT);
  $hash = password_hash($code, PASSWORD_DEFAULT);

  $stmt = $db->prepare("
    INSERT INTO email_verifications (user_id, token_hash, expires_at)
    VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? SECOND))
  ");
  $stmt->bind_param("isi", $user_id, $hash, $ttl_seconds);
  $stmt->execute();
  $stmt->close();

  return $code;
}

/* ---------- Handle POST (single page: login or register) ---------- */
$action = (string)($_POST['action'] ?? '');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {

  /* ===================== LOGIN ===================== */
  if ($action === 'login') {

    $email = trim((string)($_POST['email'] ?? ''));
    $pass  = (string)($_POST['password'] ?? '');

    if ($email === "" || $pass === "") {
      $err = "Enter your email and password.";
    } else {

      $stmt = $mysqli->prepare("
        SELECT user_id, full_name, email, password_hash, role, account_status,
               email_verified_at, twofa_enabled,
               failed_login_attempts, lock_until
        FROM users
        WHERE email = ?
        LIMIT 1
      ");
      $stmt->bind_param("s", $email);
      $stmt->execute();
      $u = $stmt->get_result()->fetch_assoc();
      $stmt->close();

      $genericErr = "Invalid credentials.";

      if (!$u) {
        $err = $genericErr;
      } else {
        $uid = (int)$u['user_id'];

        if (is_locked($u)) {
          $err = "Too many attempts. Try again later.";
        } elseif (!password_verify($pass, (string)$u['password_hash'])) {

          $stmt = $mysqli->prepare("
            UPDATE users
            SET failed_login_attempts = failed_login_attempts + 1,
                last_failed_login = NOW(),
                lock_until = IF(failed_login_attempts + 1 >= 5, DATE_ADD(NOW(), INTERVAL 15 MINUTE), lock_until)
            WHERE user_id = ?
          ");
          $stmt->bind_param("i", $uid);
          $stmt->execute();
          $stmt->close();

          $err = $genericErr;

        } else {

          // reset counters
          $stmt = $mysqli->prepare("
            UPDATE users
            SET failed_login_attempts = 0,
                lock_until = NULL,
                last_failed_login = NULL
            WHERE user_id = ?
          ");
          $stmt->bind_param("i", $uid);
          $stmt->execute();
          $stmt->close();

          /**
           * 2) ACCOUNT MUST BE APPROVED BY ADMIN
           */
          if ((string)$u['account_status'] !== 'approved') {
            header("Location: {$BASE_URL}/login.php?status=" . urlencode((string)$u['account_status']));
            exit;
          }

          /**
           * 4) FULL LOGIN (no 2FA)
           */
          session_regenerate_id(true);
          set_auth_session($u);

          $stmt = $mysqli->prepare("UPDATE users SET last_login = NOW() WHERE user_id = ?");
          $stmt->bind_param("i", $uid);
          $stmt->execute();
          $stmt->close();

          $role = (string)$u['role'];
          if ($role === 'user')    { header("Location: {$BASE_URL}/trainee/dashboard.php"); exit; }
          if ($role === 'trainer') { header("Location: {$BASE_URL}/coach/dashboard.php"); exit; }
          if ($role === 'admin')   { header("Location: {$BASE_URL}/admin/dashboard.php"); exit; }

          header("Location: {$BASE_URL}/logout.php");
          exit;
        }
      }
    }
  }

  /* ===================== REGISTER ===================== */
elseif ($action === 'register') {

  $reg_role = (string)($_POST['reg_role'] ?? 'user');
  if (!in_array($reg_role, ['user', 'trainer'], true)) $reg_role = 'user';

  $full  = trim((string)($_POST['full_name'] ?? ''));
  $email = trim((string)($_POST['reg_email'] ?? ''));
  $age   = trim((string)($_POST['age'] ?? ''));

  $pass1 = (string)($_POST['reg_password'] ?? '');
  $pass2 = (string)($_POST['reg_password2'] ?? '');

  $agree = (string)($_POST['agree'] ?? '');

  // trainer fields
  $affiliation     = trim((string)($_POST['affiliation'] ?? ''));
  $credential_type = (string)($_POST['credential_type'] ?? '');
  $credential_ref  = trim((string)($_POST['credential_ref'] ?? ''));
  $statement       = trim((string)($_POST['statement'] ?? ''));

  if ($agree !== '1') {
    $err = "You must agree to the Terms & Privacy to continue.";
  } elseif ($full === "" || $email === "" || $pass1 === "" || $pass2 === "") {
    $err = "Please complete all required registration fields.";
  } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    $err = "Enter a valid email address.";
  } elseif ($pass1 !== $pass2) {
    $err = "Passwords do not match.";
  } else {
    $hasLen = strlen($pass1) >= 8;
    $hasLow = (bool)preg_match('/[a-z]/', $pass1);
    $hasUp  = (bool)preg_match('/[A-Z]/', $pass1);
    $hasNum = (bool)preg_match('/\d/', $pass1);
    $hasSym = (bool)preg_match('/[^A-Za-z0-9]/', $pass1);

    if (!$hasLen || !$hasLow || !$hasUp || !$hasNum || !$hasSym) {
      $err = "Password must be at least 8 characters and include uppercase, lowercase, number, and symbol.";
    }
  }

  // age validation
  $ageVal = null;
  if (!$err && $age !== "") {
    $a = (int)$age;
    if ($a < 10 || $a > 100) $err = "Enter a realistic age.";
    else $ageVal = $a;
  }

  // trainer validation
  $allowed_cred = ['cpt','scs','pt','student','other'];
  if (!$err && $reg_role === 'trainer') {
    if ($affiliation === '') $err = "Trainer applications require an affiliation/organization.";
    elseif (!in_array($credential_type, $allowed_cred, true)) $err = "Select a valid credential type.";
    elseif ($statement === '' || strlen($statement) < 20) $err = "Please write a short statement (at least ~20 characters).";

    if (!$err) {
      if (!isset($_FILES['proof_file']) || (int)$_FILES['proof_file']['error'] !== UPLOAD_ERR_OK) {
        $err = "Trainer applications require a proof document (PDF/JPG/PNG).";
      } else {
        $size = (int)$_FILES['proof_file']['size'];
        if ($size <= 0 || $size > 5 * 1024 * 1024) {
          $err = "Proof file must be under 5MB.";
        }
      }
    }
  }

  if (!$err) {
    // check duplicates in users
    $stmt = $mysqli->prepare("SELECT user_id FROM users WHERE email = ? LIMIT 1");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $existsUser = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    // check duplicates in pending_registrations
    $stmt = $mysqli->prepare("SELECT pending_id FROM pending_registrations WHERE email = ? LIMIT 1");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $existsPending = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if ($existsUser) {
      $err = "That email is already registered. Try logging in.";
    } elseif ($existsPending) {
      $err = "That email has a pending verification. Please verify your email (or wait for the code to expire and resend).";
    } else {

      $role = ($reg_role === 'trainer') ? 'trainer' : 'user';
      $hash = password_hash($pass1, PASSWORD_DEFAULT);

      $mysqli->begin_transaction();

      try {
        // trainer proof (optional)
        $safeName = null;
        $mime = null;

        if ($reg_role === 'trainer') {
          $uploadDir = __DIR__ . "/uploads/trainer_proofs";
          if (!is_dir($uploadDir)) {
            if (!@mkdir($uploadDir, 0755, true) && !is_dir($uploadDir)) {
              throw new Exception("Failed to create uploads folder.");
            }
          }

          $tmpPath = (string)$_FILES['proof_file']['tmp_name'];
          $mime = function_exists('mime_content_type') ? (string)mime_content_type($tmpPath) : '';
          $ext = $mime ? ext_from_mime($mime) : null;

          if (!$ext) {
            $orig = strtolower((string)($_FILES['proof_file']['name'] ?? ''));
            if (str_ends_with($orig, '.pdf')) $ext = 'pdf';
            elseif (str_ends_with($orig, '.jpg') || str_ends_with($orig, '.jpeg')) $ext = 'jpg';
            elseif (str_ends_with($orig, '.png')) $ext = 'png';
          }
          if (!$ext) throw new Exception("Invalid proof file type. Use PDF/JPG/PNG.");

          $safeName = "trainerproof_pending_" . bin2hex(random_bytes(8)) . "." . $ext;
          $dest = $uploadDir . "/" . $safeName;

          if (!move_uploaded_file($tmpPath, $dest)) {
            throw new Exception("Failed to save proof file. Please try again.");
          }
        }

        // create pending registration
        $stmt = $mysqli->prepare("
          INSERT INTO pending_registrations
            (full_name, email, password_hash, role, age,
             affiliation, credential_type, credential_ref, statement,
             proof_file, proof_mime)
          VALUES
            (?, ?, ?, ?, ?,
             ?, ?, ?, ?,
             ?, ?)
        ");

        $ageParam = $ageVal; // can be null

        $aff  = ($reg_role === 'trainer') ? $affiliation : null;
        $ctype= ($reg_role === 'trainer') ? $credential_type : null;
        $cref = ($reg_role === 'trainer') ? $credential_ref : null;
        $stmtTxt = ($reg_role === 'trainer') ? $statement : null;

        $stmt->bind_param(
          "ssssiisssss",
          $full, $email, $hash, $role, $ageParam,
          $aff, $ctype, $cref, $stmtTxt,
          $safeName, $mime
        );

        $stmt->execute();
        $pendingId = (int)$stmt->insert_id;
        $stmt->close();

        // set verify session
        $_SESSION['pre_verify_pending_id'] = $pendingId;

        // create OTP for pending
        $otp = create_pending_email_verification($mysqli, $pendingId, 900);

        $sent = brevo_send_email(
          $email,
          $full,
          "LiftRight verification code",
          "<p>Your LiftRight verification code is:</p>
           <h2 style='letter-spacing:2px'>{$otp}</h2>
           <p>This code expires in 15 minutes.</p>"
        );

        if (!$sent) {
          $_SESSION['dev_verify_otp'] = $otp; // DEV fallback
        }

        $mysqli->commit();

        header("Location: {$BASE_URL}/verify-email.php");
        exit;

      } catch (Throwable $e) {
        $mysqli->rollback();
        $err = "Registration failed: " . $e->getMessage();
      }
    }
  }
}

  else {
    $err = "Invalid action.";
  }
}

require __DIR__ . "/includes/head.php";
?>
<body>
<div class="lr-auth-wrapper">

  <div class="lr-auth-shell">

    <!-- LEFT / BRAND -->
    <div class="lr-auth-left">
      <div class="lr-auth-logo">LiftRight</div>
      <div class="lr-auth-tagline">
        Real-time posture assessment + fatigue pattern recognition for safer lifting.
      </div>

      <ul class="lr-auth-bullets">
        <li><span class="lr-dot"></span><span>Role-based access (Trainee / Trainer / Admin)</span></li>
        <li><span class="lr-dot"></span><span>Email verification on first registration</span></li>
        <li><span class="lr-dot"></span><span>Admin approval workflow for accounts</span></li>
      </ul>
    </div>

    <!-- RIGHT / FORMS -->
    <div class="lr-auth-right">

      <div class="mb-2" style="font-weight:800; font-size: 20px;">Welcome</div>
      <div class="mb-3" style="color: var(--lr-text-muted);">
        Sign in or create an account to continue.
      </div>

      <?php if ($statusMsg): ?><div class="alert alert-warning"><?= h($statusMsg) ?></div><?php endif; ?>
      <?php if ($ok): ?><div class="alert alert-success"><?= h($ok) ?></div><?php endif; ?>
      <?php if ($err): ?><div class="alert alert-danger"><?= h($err) ?></div><?php endif; ?>

      <!-- Tabs -->
      <div class="lr-auth-tabs" role="tablist" aria-label="Auth tabs">
        <button type="button" class="lr-auth-tab active" data-tab="login">Sign in</button>
        <button type="button" class="lr-auth-tab" data-tab="register">Create account</button>
      </div>

      <!-- LOGIN PANEL -->
      <div class="lr-auth-panel active" id="panel-login">
        <form method="post" class="d-grid gap-2" autocomplete="off">
          <input type="hidden" name="action" value="login">

          <div>
            <label class="form-label">Email</label>
            <input name="email" type="email" class="form-control" required
                   placeholder="you@example.com"
                   value="<?= h($_POST['email'] ?? '') ?>">
          </div>

          <div class="lr-pass-row">
            <label class="form-label">Password</label>
            <input id="loginPass" name="password" type="password" class="form-control" required placeholder="••••••••">
            <button class="lr-eye-btn" type="button" data-toggle="#loginPass" aria-label="Show password">👁</button>
          </div>

          <button class="btn btn-primary mt-2">Login</button>
        </form>
      </div>

      <!-- REGISTER PANEL -->
      <div class="lr-auth-panel" id="panel-register">
        <form method="post" class="d-grid gap-2" id="regForm" enctype="multipart/form-data" autocomplete="off">
          <input type="hidden" name="action" value="register">

          <div>
            <label class="form-label">Register as</label>
            <select name="reg_role" class="form-control" id="regRole" required>
              <option value="user" selected>Trainee</option>
              <option value="trainer">Trainer</option>
            </select>
            <div class="form-text text-muted">Trainer requires credentials submission.</div>
          </div>

          <!-- Trainer-only fields -->
          <div class="lr-trainer-only" style="display:none;" id="trainerFields">
            <div>
              <label class="form-label">Affiliation / Organization</label>
              <input name="affiliation" class="form-control" placeholder="Gym / School / Independent"
                     value="<?= h($_POST['affiliation'] ?? '') ?>">
            </div>

            <div>
              <label class="form-label">Credential type</label>
              <select name="credential_type" class="form-control">
                <option value="">Select…</option>
                <option value="cpt">Certified Personal Trainer</option>
                <option value="scs">Strength & Conditioning Coach</option>
                <option value="pt">Physical Therapist</option>
                <option value="student">Student / In training</option>
                <option value="other">Other</option>
              </select>
            </div>

            <div>
              <label class="form-label">Credential ID / URL (optional)</label>
              <input name="credential_ref" class="form-control" placeholder="ID number or link"
                     value="<?= h($_POST['credential_ref'] ?? '') ?>">
            </div>

            <div>
              <label class="form-label">Short statement</label>
              <textarea name="statement" class="form-control" rows="3"
                        placeholder="Why do you want trainer access?"><?= h($_POST['statement'] ?? '') ?></textarea>
            </div>

            <div>
              <label class="form-label">Upload proof (PDF/JPG/PNG, max 5MB)</label>
              <input type="file" name="proof_file" class="form-control" accept=".pdf,.jpg,.jpeg,.png">
            </div>

            <div class="alert alert-info" style="margin: 4px 0 0;">
              Trainer accounts remain <b>pending</b> until admin reviews credentials.
            </div>
          </div>

          <div>
            <label class="form-label">Full name</label>
            <input name="full_name" class="form-control" required
                   placeholder="Juan Dela Cruz"
                   value="<?= h($_POST['full_name'] ?? '') ?>">
          </div>

          <div>
            <label class="form-label">Email</label>
            <input name="reg_email" type="email" class="form-control" required
                   placeholder="you@example.com"
                   value="<?= h($_POST['reg_email'] ?? '') ?>">
          </div>

          <div>
            <label class="form-label">Age (optional)</label>
            <input name="age" type="number" min="10" max="100" class="form-control"
                   placeholder="18"
                   value="<?= h($_POST['age'] ?? '') ?>">
          </div>

          <div class="lr-pass-row">
            <label class="form-label">Password</label>
            <input id="regPass" name="reg_password" type="password" class="form-control" required
                   placeholder="At least 8 characters">
            <button class="lr-eye-btn" type="button" data-toggle="#regPass" aria-label="Show password">👁</button>

            <div class="mt-2 lr-meter"><div id="passBar"></div></div>

            <ul class="lr-req" id="passReq">
              <li class="bad" data-req="len">At least 8 characters</li>
              <li class="bad" data-req="low">Lowercase letter</li>
              <li class="bad" data-req="up">Uppercase letter</li>
              <li class="bad" data-req="num">Number</li>
              <li class="bad" data-req="sym">Special character (!@#$...)</li>
            </ul>
          </div>

          <div class="lr-pass-row">
            <label class="form-label">Confirm password</label>
            <input id="regPass2" name="reg_password2" type="password" class="form-control" required
                   placeholder="Repeat password">
            <button class="lr-eye-btn" type="button" data-toggle="#regPass2" aria-label="Show password">👁</button>
            <div class="form-text text-muted" id="matchText"></div>
          </div>

          <label class="lr-inline" style="margin-top:8px; color: var(--lr-text-muted);">
            <input type="checkbox" name="agree" value="1" required>
            <span>I agree to the Terms & Privacy (prototype).</span>
          </label>

          <button class="btn btn-outline-light mt-2" id="regBtn" disabled>Create account</button>
        </form>
      </div>

      <div class="lr-auth-divider"></div>
      <div style="color: var(--lr-text-muted); font-size:.95rem;">
        By continuing, you agree to LiftRight’s Terms & Privacy (prototype).
      </div>

    </div>
  </div>
</div>

<script>
  // Tabs toggle
  const tabs = document.querySelectorAll('.lr-auth-tab');
  const loginPanel = document.getElementById('panel-login');
  const regPanel   = document.getElementById('panel-register');

  tabs.forEach(btn => {
    btn.addEventListener('click', () => {
      tabs.forEach(x => x.classList.remove('active'));
      btn.classList.add('active');

      const t = btn.dataset.tab;
      loginPanel.classList.toggle('active', t === 'login');
      regPanel.classList.toggle('active', t === 'register');
    });
  });

  // Show/hide password
  document.querySelectorAll('[data-toggle]').forEach(btn => {
    btn.addEventListener('click', () => {
      const sel = btn.getAttribute('data-toggle');
      const input = document.querySelector(sel);
      if (!input) return;
      input.type = (input.type === 'password') ? 'text' : 'password';
    });
  });

  // Trainer fields toggle
  const regRole = document.getElementById('regRole');
  const trainerFields = document.getElementById('trainerFields');
  function syncTrainerFields(){
    const isTrainer = regRole && regRole.value === 'trainer';
    if (trainerFields) trainerFields.style.display = isTrainer ? 'block' : 'none';
  }
  if (regRole) {
    regRole.addEventListener('change', syncTrainerFields);
    syncTrainerFields();
  }

  // Password strength rules
  const pass1 = document.getElementById('regPass');
  const pass2 = document.getElementById('regPass2');
  const bar = document.getElementById('passBar');
  const reqList = document.getElementById('passReq');
  const matchText = document.getElementById('matchText');
  const regBtn = document.getElementById('regBtn');
  const regForm = document.getElementById('regForm');

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
    if (!pass1 || !pass2) return;

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

    const agree = regForm.querySelector('input[name="agree"]');
    const agreeOk = agree && agree.checked;

    const allow = (s === 5) && match && agreeOk;
    regBtn.disabled = !allow;
  }

  if (pass1 && pass2 && regForm) {
    pass1.addEventListener('input', syncPasswordUI);
    pass2.addEventListener('input', syncPasswordUI);
    regForm.addEventListener('input', syncPasswordUI);
    syncPasswordUI();
  }
</script>
</body>
</html>
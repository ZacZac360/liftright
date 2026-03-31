<?php
// liftright/web/config/auth.php

declare(strict_types=1);

if (session_status() !== PHP_SESSION_ACTIVE) {
  session_start();
}

require_once __DIR__ . '/audit.php';

/* =========================================================
   BASIC AUTH
========================================================= */

function is_logged_in(): bool {
  return isset($_SESSION['user_id'], $_SESSION['role']);
}

function require_approved(string $redirectTo = "/login.php"): void {
  global $BASE_URL;

  if (!is_logged_in()) {
    header("Location: {$BASE_URL}{$redirectTo}");
    exit;
  }

  $status = (string)($_SESSION['account_status'] ?? 'approved');

  if ($status !== 'approved') {
    $_SESSION = [];

    if (ini_get("session.use_cookies")) {
      $params = session_get_cookie_params();
      setcookie(
        session_name(),
        '',
        time() - 42000,
        $params["path"],
        $params["domain"],
        $params["secure"],
        $params["httponly"]
      );
    }

    session_destroy();

    $q = urlencode($status);
    header("Location: {$BASE_URL}{$redirectTo}?status={$q}");
    exit;
  }
}

function require_login(string $redirectTo = "/login.php"): void {
  require_approved($redirectTo);
}

function require_role(array $roles, string $redirectTo = "/index.php"): void {
  global $BASE_URL;

  require_login();

  $role = (string)($_SESSION['role'] ?? '');
  if (!in_array($role, $roles, true)) {
    header("Location: {$BASE_URL}{$redirectTo}");
    exit;
  }
}

function current_user_id(): int {
  return (int)($_SESSION['user_id'] ?? 0);
}

function set_auth_session(array $user): void {
  $_SESSION['user_id']        = (int)($user['user_id'] ?? 0);
  $_SESSION['role']           = (string)($user['role'] ?? '');
  $_SESSION['full_name']      = (string)($user['full_name'] ?? '');
  $_SESSION['email']          = (string)($user['email'] ?? '');
  $_SESSION['account_status'] = (string)($user['account_status'] ?? 'pending');
  $_SESSION['theme']          = (string)($user['theme'] ?? 'default');
}

/* =========================================================
   REQUEST META
========================================================= */

if (!function_exists('client_ip')) {
  function client_ip(): string {
    return (string)($_SERVER['REMOTE_ADDR'] ?? '');
  }
}

if (!function_exists('client_ua')) {
  function client_ua(): string {
    return substr((string)($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 255);
  }
}

/* =========================================================
   AUDIT LOG
========================================================= */

if (!function_exists('auth_log')) {
  function auth_log(mysqli $db, $user_id, string $type, array $meta = []): void {
    $ip = client_ip();
    $ua = client_ua();
    $meta_json = empty($meta) ? null : json_encode($meta, JSON_UNESCAPED_SLASHES);

    $stmt = $db->prepare("
      INSERT INTO auth_audit_logs (user_id, event_type, ip_address, user_agent, meta)
      VALUES (?, ?, ?, ?, ?)
    ");

    if ($user_id === null) {
      $null = null;
      $stmt->bind_param("issss", $null, $type, $ip, $ua, $meta_json);
    } else {
      $uid = (int)$user_id;
      $stmt->bind_param("issss", $uid, $type, $ip, $ua, $meta_json);
    }

    $stmt->execute();
    $stmt->close();
  }
}

/* =========================================================
   LOGIN OTP HELPERS
========================================================= */

if (!function_exists('generate_otp_code')) {
  function generate_otp_code(): string {
    return str_pad((string)random_int(0, 999999), 6, '0', STR_PAD_LEFT);
  }
}

if (!function_exists('create_login_otp')) {
  function create_login_otp(mysqli $db, int $user_id, int $ttl_seconds = 300): string {
    $code = generate_otp_code();
    $hash = password_hash($code, PASSWORD_DEFAULT);

    $stmt = $db->prepare("
      INSERT INTO login_otps (user_id, otp_hash, expires_at)
      VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? SECOND))
    ");
    $stmt->bind_param("isi", $user_id, $hash, $ttl_seconds);
    $stmt->execute();
    $stmt->close();

    return $code;
  }
}

if (!function_exists('verify_latest_login_otp')) {
  function verify_latest_login_otp(mysqli $db, int $user_id, string $code): array {
    $stmt = $db->prepare("
      SELECT otp_id, otp_hash, expires_at, attempts, consumed_at
      FROM login_otps
      WHERE user_id = ?
      ORDER BY otp_id DESC
      LIMIT 1
    ");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $otp = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$otp) return ['ok' => false, 'reason' => 'no_otp'];
    if (!empty($otp['consumed_at'])) return ['ok' => false, 'reason' => 'used'];
    if ((int)$otp['attempts'] >= 5) return ['ok' => false, 'reason' => 'too_many_attempts'];

    if (strtotime((string)$otp['expires_at']) < time()) {
      return ['ok' => false, 'reason' => 'expired'];
    }

    if (!password_verify($code, (string)$otp['otp_hash'])) {
      $otp_id = (int)$otp['otp_id'];
      $stmt = $db->prepare("UPDATE login_otps SET attempts = attempts + 1 WHERE otp_id = ?");
      $stmt->bind_param("i", $otp_id);
      $stmt->execute();
      $stmt->close();

      return ['ok' => false, 'reason' => 'invalid'];
    }

    $otp_id = (int)$otp['otp_id'];
    $stmt = $db->prepare("UPDATE login_otps SET consumed_at = NOW() WHERE otp_id = ?");
    $stmt->bind_param("i", $otp_id);
    $stmt->execute();
    $stmt->close();

    return ['ok' => true, 'reason' => 'ok'];
  }
}

/* =========================================================
   EMAIL VERIFICATION HELPERS
========================================================= */

if (!function_exists('create_user_email_otp_record')) {
  function create_user_email_otp_record(mysqli $db, int $user_id, int $ttl_seconds = 900): string {
    $stmt = $db->prepare("
      UPDATE email_verifications
      SET consumed_at = NOW()
      WHERE user_id = ? AND consumed_at IS NULL
    ");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $stmt->close();

    $code = generate_otp_code();
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
}

if (!function_exists('create_pending_email_otp_record')) {
  function create_pending_email_otp_record(mysqli $db, int $pending_id, int $ttl_seconds = 900): string {
    $stmt = $db->prepare("
      UPDATE email_verifications
      SET consumed_at = NOW()
      WHERE pending_id = ? AND consumed_at IS NULL
    ");
    $stmt->bind_param("i", $pending_id);
    $stmt->execute();
    $stmt->close();

    $code = generate_otp_code();
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
}

if (!function_exists('verify_active_email_otp_for_user')) {
  function verify_active_email_otp_for_user(mysqli $db, int $user_id, string $otp): array {
    $stmt = $db->prepare("
      SELECT verif_id, token_hash, expires_at
      FROM email_verifications
      WHERE user_id = ? AND consumed_at IS NULL
      ORDER BY created_at DESC
      LIMIT 1
    ");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$row) return ['ok' => false, 'reason' => 'no_active_code'];

    if (strtotime((string)$row['expires_at']) < time()) {
      $vid = (int)$row['verif_id'];
      $stmt = $db->prepare("UPDATE email_verifications SET consumed_at = NOW() WHERE verif_id = ?");
      $stmt->bind_param("i", $vid);
      $stmt->execute();
      $stmt->close();

      return ['ok' => false, 'reason' => 'expired'];
    }

    if (!password_verify($otp, (string)$row['token_hash'])) {
      return ['ok' => false, 'reason' => 'invalid'];
    }

    $vid = (int)$row['verif_id'];

    $stmt = $db->prepare("UPDATE email_verifications SET consumed_at = NOW() WHERE verif_id = ?");
    $stmt->bind_param("i", $vid);
    $stmt->execute();
    $stmt->close();

    $stmt = $db->prepare("
      UPDATE email_verifications
      SET consumed_at = NOW()
      WHERE user_id = ? AND consumed_at IS NULL
    ");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $stmt->close();

    return ['ok' => true, 'reason' => 'ok'];
  }
}

if (!function_exists('verify_active_email_otp_for_pending')) {
  function verify_active_email_otp_for_pending(mysqli $db, int $pending_id, string $otp): array {
    $stmt = $db->prepare("
      SELECT verif_id, token_hash, expires_at
      FROM email_verifications
      WHERE pending_id = ? AND consumed_at IS NULL
      ORDER BY created_at DESC
      LIMIT 1
    ");
    $stmt->bind_param("i", $pending_id);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$row) return ['ok' => false, 'reason' => 'no_active_code'];

    if (strtotime((string)$row['expires_at']) < time()) {
      $vid = (int)$row['verif_id'];
      $stmt = $db->prepare("UPDATE email_verifications SET consumed_at = NOW() WHERE verif_id = ?");
      $stmt->bind_param("i", $vid);
      $stmt->execute();
      $stmt->close();

      return ['ok' => false, 'reason' => 'expired'];
    }

    if (!password_verify($otp, (string)$row['token_hash'])) {
      return ['ok' => false, 'reason' => 'invalid'];
    }

    $vid = (int)$row['verif_id'];

    $stmt = $db->prepare("UPDATE email_verifications SET consumed_at = NOW() WHERE verif_id = ?");
    $stmt->bind_param("i", $vid);
    $stmt->execute();
    $stmt->close();

    $stmt = $db->prepare("
      UPDATE email_verifications
      SET consumed_at = NOW()
      WHERE pending_id = ? AND consumed_at IS NULL
    ");
    $stmt->bind_param("i", $pending_id);
    $stmt->execute();
    $stmt->close();

    return ['ok' => true, 'reason' => 'ok'];
  }
}

if (!function_exists('mark_user_email_verified')) {
  function mark_user_email_verified(mysqli $db, int $user_id): void {
    $stmt = $db->prepare("
      UPDATE users
      SET email_verified_at = NOW()
      WHERE user_id = ?
    ");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $stmt->close();
  }
}

/* =========================================================
   ADMIN PASSWORD RE-CHECK
========================================================= */

if (!function_exists('require_admin_password_confirm')) {
  function require_admin_password_confirm(mysqli $db, int $admin_id, string $plainPassword): void {
    if ($admin_id <= 0) {
      throw new Exception("Invalid admin session.");
    }

    if ($plainPassword === '') {
      throw new Exception("Admin password is required.");
    }

    $stmt = $db->prepare("
      SELECT password_hash
      FROM users
      WHERE user_id = ? AND role = 'admin'
      LIMIT 1
    ");
    $stmt->bind_param("i", $admin_id);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$row || !password_verify($plainPassword, (string)$row['password_hash'])) {
      throw new Exception("Incorrect admin password.");
    }
  }
}

if (!function_exists('generate_reset_token_plain')) {
  function generate_reset_token_plain(): string {
    return bin2hex(random_bytes(32));
  }
}

if (!function_exists('create_password_reset_token')) {
  function create_password_reset_token(mysqli $db, int $user_id, int $ttl_seconds = 3600): string {
    $stmt = $db->prepare("
      UPDATE password_resets
      SET consumed_at = NOW()
      WHERE user_id = ? AND consumed_at IS NULL
    ");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $stmt->close();

    $plain = generate_reset_token_plain();
    $hash = password_hash($plain, PASSWORD_DEFAULT);

    $stmt = $db->prepare("
      INSERT INTO password_resets (user_id, token_hash, expires_at)
      VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? SECOND))
    ");
    $stmt->bind_param("isi", $user_id, $hash, $ttl_seconds);
    $stmt->execute();
    $stmt->close();

    return $plain;
  }
}

if (!function_exists('validate_password_reset_token')) {
  function validate_password_reset_token(mysqli $db, int $user_id, string $token): array {
    $stmt = $db->prepare("
      SELECT reset_id, token_hash, expires_at, consumed_at
      FROM password_resets
      WHERE user_id = ?
      ORDER BY reset_id DESC
      LIMIT 1
    ");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$row) return ['ok' => false, 'reason' => 'no_token'];
    if (!empty($row['consumed_at'])) return ['ok' => false, 'reason' => 'used'];

    if (strtotime((string)$row['expires_at']) < time()) {
      $rid = (int)$row['reset_id'];
      $stmt = $db->prepare("UPDATE password_resets SET consumed_at = NOW() WHERE reset_id = ?");
      $stmt->bind_param("i", $rid);
      $stmt->execute();
      $stmt->close();

      return ['ok' => false, 'reason' => 'expired'];
    }

    if (!password_verify($token, (string)$row['token_hash'])) {
      return ['ok' => false, 'reason' => 'invalid'];
    }

    return ['ok' => true, 'reason' => 'ok', 'reset_id' => (int)$row['reset_id']];
  }
}

if (!function_exists('consume_password_reset_token')) {
  function consume_password_reset_token(mysqli $db, int $reset_id): void {
    $stmt = $db->prepare("
      UPDATE password_resets
      SET consumed_at = NOW()
      WHERE reset_id = ?
      LIMIT 1
    ");
    $stmt->bind_param("i", $reset_id);
    $stmt->execute();
    $stmt->close();
  }
}
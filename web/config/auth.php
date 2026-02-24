<?php
// liftright/web/config/auth.php

declare(strict_types=1);

if (session_status() !== PHP_SESSION_ACTIVE) {
  session_start();
}

/**
 * Basic check (session presence only)
 */
function is_logged_in(): bool {
  return isset($_SESSION['user_id'], $_SESSION['role']);
}

/**
 * Stronger gate: user must be logged in AND approved.
 * If not approved, force logout and redirect to login with status flag.
 */
function require_approved(string $redirectTo = "/login.php"): void {
  global $BASE_URL;

  // Not logged in at all
  if (!is_logged_in()) {
    header("Location: {$BASE_URL}{$redirectTo}");
    exit;
  }

  $status = (string)($_SESSION['account_status'] ?? 'approved');

  // Allow only approved users
  if ($status !== 'approved') {
    // Kill session for safety
    $_SESSION = [];
    if (ini_get("session.use_cookies")) {
      $params = session_get_cookie_params();
      setcookie(session_name(), '', time() - 42000,
        $params["path"], $params["domain"],
        $params["secure"], $params["httponly"]
      );
    }
    session_destroy();

    // Redirect with status param
    $q = urlencode($status); // pending / rejected / suspended
    header("Location: {$BASE_URL}{$redirectTo}?status={$q}");
    exit;
  }
}

/**
 * Use this for any protected page. This now enforces "approved".
 */
function require_login(string $redirectTo = "/login.php"): void {
  // require_approved already checks is_logged_in internally
  require_approved($redirectTo);
}

/**
 * Role gate (also enforces approved via require_login)
 */
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

/**
 * Call this right after successful login query.
 * Ensures required session keys exist consistently.
 *
 * Expected $user keys: user_id, role, full_name, email, account_status
 */
function set_auth_session(array $user): void {
  $_SESSION['user_id'] = (int)($user['user_id'] ?? 0);
  $_SESSION['role'] = (string)($user['role'] ?? '');
  $_SESSION['full_name'] = (string)($user['full_name'] ?? '');
  $_SESSION['email'] = (string)($user['email'] ?? '');
  $_SESSION['account_status'] = (string)($user['account_status'] ?? 'pending');
}

// config/auth.php (append)

if (!function_exists('client_ip')) {
  function client_ip(): string {
    // basic; fine for thesis / local
    return (string)($_SERVER['REMOTE_ADDR'] ?? '');
  }
}

if (!function_exists('client_ua')) {
  function client_ua(): string {
    $ua = (string)($_SERVER['HTTP_USER_AGENT'] ?? '');
    return substr($ua, 0, 255);
  }
}

if (!function_exists('auth_log')) {
    function auth_log(mysqli $db, $user_id, string $type, array $meta = []): void {
    $ip = (string)($_SERVER['REMOTE_ADDR'] ?? '');
    $ua = substr((string)($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 255);
    $meta_json = empty($meta) ? null : json_encode($meta, JSON_UNESCAPED_SLASHES);

    $stmt = $db->prepare("
      INSERT INTO auth_audit_logs (user_id, event_type, ip_address, user_agent, meta)
      VALUES (?, ?, ?, ?, ?)
    ");

    // allow NULL user_id
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

    return $code; // return plaintext ONLY so you can send via email (never store plaintext)
  }
}

if (!function_exists('verify_latest_login_otp')) {
  function verify_latest_login_otp(mysqli $db, int $user_id, string $code): array {
    // returns ['ok'=>bool, 'reason'=>string]
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

    // expired?
    if (strtotime((string)$otp['expires_at']) < time()) {
      return ['ok' => false, 'reason' => 'expired'];
    }

    if (!password_verify($code, (string)$otp['otp_hash'])) {
      // bump attempts
      $otp_id = (int)$otp['otp_id'];
      $stmt = $db->prepare("UPDATE login_otps SET attempts = attempts + 1 WHERE otp_id = ?");
      $stmt->bind_param("i", $otp_id);
      $stmt->execute();
      $stmt->close();
      return ['ok' => false, 'reason' => 'invalid'];
    }

    // mark consumed
    $otp_id = (int)$otp['otp_id'];
    $stmt = $db->prepare("UPDATE login_otps SET consumed_at = NOW() WHERE otp_id = ?");
    $stmt->bind_param("i", $otp_id);
    $stmt->execute();
    $stmt->close();

    return ['ok' => true, 'reason' => 'ok'];
  }
}
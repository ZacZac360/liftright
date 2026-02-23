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
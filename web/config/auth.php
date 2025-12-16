<?php
// liftright/web/config/auth.php

declare(strict_types=1);

if (session_status() !== PHP_SESSION_ACTIVE) {
  session_start();
}

function is_logged_in(): bool {
  return isset($_SESSION['user_id'], $_SESSION['role']);
}

function require_login(string $redirectTo = "/login.php"): void {
  global $BASE_URL;
  if (!is_logged_in()) {
    header("Location: {$BASE_URL}{$redirectTo}");
    exit;
  }
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

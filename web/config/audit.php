<?php
// liftright/web/config/audit.php
declare(strict_types=1);

if (!function_exists('audit_safe_json')) {
  function audit_safe_json(array $data): string {
    return json_encode($data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
  }
}

if (!function_exists('audit_log_event')) {
  function audit_log_event(mysqli $db, ?int $user_id, string $event_type, array $meta = []): void {
    if (function_exists('auth_log')) {
      auth_log($db, $user_id, $event_type, $meta);
      return;
    }

    $ip = (string)($_SERVER['REMOTE_ADDR'] ?? '');
    $ua = substr((string)($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 255);
    $meta_json = empty($meta) ? null : audit_safe_json($meta);

    $stmt = $db->prepare("
      INSERT INTO auth_audit_logs (user_id, event_type, ip_address, user_agent, meta)
      VALUES (?, ?, ?, ?, ?)
    ");

    if ($user_id === null) {
      $null = null;
      $stmt->bind_param("issss", $null, $event_type, $ip, $ua, $meta_json);
    } else {
      $stmt->bind_param("issss", $user_id, $event_type, $ip, $ua, $meta_json);
    }

    $stmt->execute();
    $stmt->close();
  }
}

if (!function_exists('audit_admin_action')) {
  function audit_admin_action(
    mysqli $db,
    int $admin_id,
    string $event_type,
    ?int $target_user_id = null,
    array $meta = []
  ): void {
    $payload = $meta;
    if ($target_user_id !== null) {
      $payload['target_user_id'] = $target_user_id;
    }
    audit_log_event($db, $admin_id, $event_type, $payload);
  }
}

if (!function_exists('audit_fetch_user_brief')) {
  function audit_fetch_user_brief(mysqli $db, int $user_id): ?array {
    if ($user_id <= 0) return null;

    $stmt = $db->prepare("
      SELECT user_id, full_name, email, role, account_status, trainer_id
      FROM users
      WHERE user_id = ?
      LIMIT 1
    ");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    return $row ?: null;
  }
}
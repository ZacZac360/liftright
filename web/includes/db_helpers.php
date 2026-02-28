<?php
declare(strict_types=1);

if (!function_exists('table_exists')) {
  function table_exists(mysqli $db, string $table): bool {
    static $cache = [];
    if (isset($cache[$table])) return $cache[$table];

    $stmt = $db->prepare("
      SELECT 1
      FROM information_schema.tables
      WHERE table_schema = DATABASE()
        AND table_name = ?
      LIMIT 1
    ");
    $stmt->bind_param("s", $table);
    $stmt->execute();
    $res = $stmt->get_result();
    $exists = ($res && $res->num_rows > 0);
    $stmt->close();

    return $cache[$table] = $exists;
  }
}

if (!function_exists('pending_unlink_requests_count')) {
  function pending_unlink_requests_count(mysqli $db): int {
    if (!table_exists($db, 'trainer_invites')) return 0;

    $stmt = $db->prepare("
      SELECT COUNT(*) AS c
      FROM trainer_invites
      WHERE status = 'unlink_requested'
    ");
    if (!$stmt) return 0;

    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();
    return (int)($row['c'] ?? 0);
  }
}
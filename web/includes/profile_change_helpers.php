<?php
declare(strict_types=1);

function get_pending_profile_request(mysqli $db, int $user_id): ?array {
  if ($user_id <= 0) return null;

  $stmt = $db->prepare("
    SELECT *
    FROM profile_change_requests
    WHERE user_id = ? AND status = 'pending'
    ORDER BY created_at DESC
    LIMIT 1
  ");
  $stmt->bind_param("i", $user_id);
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
  $stmt->close();

  return $row ?: null;
}

function cancel_profile_request(mysqli $db, int $request_id, int $user_id): bool {
  if ($request_id <= 0 || $user_id <= 0) return false;

  $stmt = $db->prepare("
    UPDATE profile_change_requests
    SET status = 'cancelled', reviewed_at = NOW()
    WHERE request_id = ? AND user_id = ? AND status = 'pending'
  ");
  $stmt->bind_param("ii", $request_id, $user_id);
  $stmt->execute();
  $ok = ($stmt->affected_rows > 0);
  $stmt->close();

  return $ok;
}

function notify_all_admins(mysqli $db, string $message, ?int $log_id = null, ?int $from_user_id = null): void {
  $admins = [];

  $stmt = $db->prepare("SELECT user_id FROM users WHERE role = 'admin'");
  $stmt->execute();
  $res = $stmt->get_result();
  while ($r = $res->fetch_assoc()) $admins[] = (int)$r['user_id'];
  $stmt->close();

  foreach ($admins as $admin_id) {
    $stmt = $db->prepare("
      INSERT INTO notifications (user_id, notif_type, message, log_id, from_user_id)
      VALUES (?, 'system', ?, ?, ?)
    ");
    // bind nullable bigints/ints safely
    $log = $log_id;
    $from = $from_user_id;
    $stmt->bind_param("isii", $admin_id, $message, $log, $from);
    $stmt->execute();
    $stmt->close();
  }
}

function notify_user(mysqli $db, int $user_id, string $type, string $message, ?int $from_user_id = null): void {
  $allowed = ['assignment','review_posted','session_uploaded','system'];
  if (!in_array($type, $allowed, true)) $type = 'system';

  $from = $from_user_id;
  $nullLog = null;

  $stmt = $db->prepare("
    INSERT INTO notifications (user_id, notif_type, message, log_id, from_user_id)
    VALUES (?, ?, ?, ?, ?)
  ");
  $stmt->bind_param("issii", $user_id, $type, $message, $nullLog, $from);
  $stmt->execute();
  $stmt->close();
}
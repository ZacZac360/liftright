<?php
session_start();
require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/auth.php';

require_role(['user','trainer','admin']); // admin can also cancel if needed

$user_id = (int)($_SESSION['user_id'] ?? 0);
$request_id = (int)($_POST['cancel_id'] ?? 0);

if ($user_id <= 0 || $request_id <= 0) {
  header("Location: {$BASE_URL}/index.php");
  exit;
}

$stmt = $mysqli->prepare("
  UPDATE profile_change_requests
  SET status = 'cancelled'
  WHERE request_id = ?
    AND user_id = ?
    AND status = 'pending'
");
$stmt->bind_param("ii", $request_id, $user_id);
$stmt->execute();
$stmt->close();

// role-aware return
$role = $_SESSION['role'] ?? 'user';
$return = ($role === 'trainer') ? "{$BASE_URL}/coach/profile.php" : "{$BASE_URL}/trainee/profile.php";
header("Location: {$return}?cancelled=1");
exit;
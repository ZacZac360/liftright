<?php
// liftright/web/api/set-theme.php
session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

header('Content-Type: application/json');

if (!isset($_SESSION['user_id'])) {
  http_response_code(401);
  echo json_encode(['success' => false, 'message' => 'Not logged in']);
  exit;
}

$allowed = ['default','light','dark','contrast'];
$input = json_decode(file_get_contents('php://input'), true) ?: [];
$theme = (string)($input['theme'] ?? 'default');

if (!in_array($theme, $allowed, true)) {
  http_response_code(400);
  echo json_encode(['success' => false, 'message' => 'Invalid theme']);
  exit;
}

$user_id = (int)$_SESSION['user_id'];

$stmt = $mysqli->prepare("UPDATE users SET theme = ? WHERE user_id = ? LIMIT 1");
$stmt->bind_param("si", $theme, $user_id);
$ok = $stmt->execute();
$stmt->close();

if ($ok) {
  $_SESSION['theme'] = $theme;
  echo json_encode(['success' => true, 'theme' => $theme]);
} else {
  http_response_code(500);
  echo json_encode(['success' => false, 'message' => 'DB update failed']);
}
<?php
// liftright/web/admin/open-proof.php
session_start();

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['admin']);

$app_id = (int)($_GET['app_id'] ?? 0);
if ($app_id <= 0) {
  http_response_code(400);
  echo "Invalid request.";
  exit;
}

// Get proof filename from DB
$stmt = $mysqli->prepare("
  SELECT proof_file
  FROM trainer_applications
  WHERE app_id = ?
  LIMIT 1
");
$stmt->bind_param("i", $app_id);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

$proof = (string)($row['proof_file'] ?? '');
if ($proof === '') {
  http_response_code(404);
  echo "File not found.";
  exit;
}

// Safety: reject path traversal / weird filenames
$base = basename($proof);
if ($base !== $proof) {
  http_response_code(400);
  echo "Invalid file.";
  exit;
}

// File path
$path = realpath(__DIR__ . '/../uploads/trainer_proofs/' . $base);
$root = realpath(__DIR__ . '/../uploads/trainer_proofs');

if (!$path || !$root || strpos($path, $root) !== 0 || !is_file($path)) {
  http_response_code(404);
  echo "File not found.";
  exit;
}

// Detect content type (allow only pdf/jpg/png)
$mime = function_exists('mime_content_type') ? (string)mime_content_type($path) : '';
$allowed = ['application/pdf', 'image/jpeg', 'image/png'];

if (!in_array($mime, $allowed, true)) {
  http_response_code(415);
  echo "Unsupported file type.";
  exit;
}

// Serve inline (browser opens PDF/images)
header('X-Content-Type-Options: nosniff');
header('Content-Type: ' . $mime);
header('Content-Length: ' . filesize($path));

// Choose inline disposition
// If you want download instead: attachment
header('Content-Disposition: inline; filename="' . addslashes($base) . '"');

readfile($path);
exit;
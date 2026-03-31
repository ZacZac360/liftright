<?php
session_start();

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  http_response_code(405);
  echo json_encode(['success' => false, 'message' => 'Method not allowed']);
  exit;
}

function brevo_send_email(string $toEmail, string $toName, string $subject, string $html): bool {
  if (!defined('BREVO_API_KEY') || !BREVO_API_KEY) return false;
  if (!defined('BREVO_SENDER_EMAIL') || !BREVO_SENDER_EMAIL) return false;

  $payload = [
    "sender" => [
      "email" => BREVO_SENDER_EMAIL,
      "name"  => defined('BREVO_SENDER_NAME') ? BREVO_SENDER_NAME : "LiftRight"
    ],
    "to" => [[ "email" => $toEmail, "name" => $toName ]],
    "subject" => $subject,
    "htmlContent" => $html
  ];

  $ch = curl_init("https://api.brevo.com/v3/smtp/email");
  curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST => true,
    CURLOPT_HTTPHEADER => [
      "accept: application/json",
      "content-type: application/json",
      "api-key: " . BREVO_API_KEY,
    ],
    CURLOPT_POSTFIELDS => json_encode($payload),
    CURLOPT_TIMEOUT => 10,
  ]);

  $resp = curl_exec($ch);
  $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
  curl_close($ch);

  return ($resp !== false && $code >= 200 && $code < 300);
}

$email = trim((string)($_POST['email'] ?? ''));
if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
  echo json_encode(['success' => true, 'message' => 'If the email exists, a reset link has been sent.']);
  exit;
}

$stmt = $mysqli->prepare("
  SELECT user_id, full_name, email
  FROM users
  WHERE email = ?
  LIMIT 1
");
$stmt->bind_param("s", $email);
$stmt->execute();
$u = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$u) {
  auth_log($mysqli, null, 'password_reset_requested', [
    'email' => $email,
    'result' => 'not_found'
  ]);

  echo json_encode(['success' => true, 'message' => 'If the email exists, a reset link has been sent.']);
  exit;
}

$user_id = (int)$u['user_id'];
$plain = create_password_reset_token($mysqli, $user_id, 3600);
$resetUrl = rtrim($BASE_URL, '/') . '/reset-password.php?u=' . $user_id . '&token=' . urlencode($plain);

$sent = brevo_send_email(
  (string)$u['email'],
  (string)$u['full_name'],
  "LiftRight password reset",
  "<p>You requested a password reset for your LiftRight account.</p>
   <p><a href=\"{$resetUrl}\">Reset your password</a></p>
   <p>This link expires in 1 hour.</p>"
);

auth_log($mysqli, $user_id, 'password_reset_requested', [
  'email' => (string)$u['email']
]);

if (!$sent) {
  echo json_encode([
    'success' => true,
    'message' => 'DEV: Reset link generated (Brevo not configured).',
    'dev_reset_url' => $resetUrl
  ]);
  exit;
}

echo json_encode(['success' => true, 'message' => 'If the email exists, a reset link has been sent.']);
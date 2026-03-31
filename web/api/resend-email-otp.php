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

$pending_id = (int)($_SESSION['pre_verify_pending_id'] ?? 0);
$user_id    = (int)($_SESSION['pre_verify_user_id'] ?? 0);

if ($pending_id <= 0 && $user_id <= 0) {
  http_response_code(401);
  echo json_encode(['success' => false, 'message' => 'No verification session.']);
  exit;
}

if ($pending_id > 0) {
  $stmt = $mysqli->prepare("
    SELECT pending_id, full_name, email
    FROM pending_registrations
    WHERE pending_id = ?
    LIMIT 1
  ");
  $stmt->bind_param("i", $pending_id);
  $stmt->execute();
  $p = $stmt->get_result()->fetch_assoc();
  $stmt->close();

  if (!$p) {
    unset($_SESSION['pre_verify_pending_id'], $_SESSION['dev_verify_otp']);
    http_response_code(404);
    echo json_encode(['success' => false, 'message' => 'Pending registration not found.']);
    exit;
  }

  $stmt = $mysqli->prepare("
    SELECT created_at
    FROM email_verifications
    WHERE pending_id = ?
    ORDER BY created_at DESC
    LIMIT 1
  ");
  $stmt->bind_param("i", $pending_id);
  $stmt->execute();
  $last = $stmt->get_result()->fetch_assoc();
  $stmt->close();

  if ($last && isset($last['created_at'])) {
    $lastTs = strtotime((string)$last['created_at']);
    if ($lastTs && (time() - $lastTs) < 60) {
      echo json_encode(['success' => false, 'message' => 'Please wait a bit before requesting another code.']);
      exit;
    }
  }

  $otp = create_pending_email_otp_record($mysqli, $pending_id, 900);

  $sent = brevo_send_email(
    (string)$p['email'],
    (string)$p['full_name'],
    "LiftRight verification code",
    "<p>Your LiftRight verification code is:</p>
     <h2 style='letter-spacing:2px'>{$otp}</h2>
     <p>This code expires in 15 minutes.</p>"
  );

  auth_log($mysqli, null, 'email_verify_sent', [
    'mode' => 'pending_registration',
    'pending_id' => $pending_id,
    'email' => (string)$p['email']
  ]);

  if (!$sent) {
    $_SESSION['dev_verify_otp'] = $otp;
    echo json_encode([
      'success' => true,
      'message' => 'DEV: OTP generated (Brevo not configured).',
      'dev_otp' => $otp
    ]);
    exit;
  }

  echo json_encode(['success' => true, 'message' => 'OTP sent.']);
  exit;
}

$stmt = $mysqli->prepare("
  SELECT user_id, full_name, email
  FROM users
  WHERE user_id = ?
  LIMIT 1
");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$u = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$u) {
  unset($_SESSION['pre_verify_user_id'], $_SESSION['dev_verify_otp']);
  http_response_code(404);
  echo json_encode(['success' => false, 'message' => 'User not found.']);
  exit;
}

$stmt = $mysqli->prepare("
  SELECT created_at
  FROM email_verifications
  WHERE user_id = ?
  ORDER BY created_at DESC
  LIMIT 1
");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$last = $stmt->get_result()->fetch_assoc();
$stmt->close();

if ($last && isset($last['created_at'])) {
  $lastTs = strtotime((string)$last['created_at']);
  if ($lastTs && (time() - $lastTs) < 60) {
    echo json_encode(['success' => false, 'message' => 'Please wait a bit before requesting another code.']);
    exit;
  }
}

$otp = create_user_email_otp_record($mysqli, $user_id, 900);

$sent = brevo_send_email(
  (string)$u['email'],
  (string)$u['full_name'],
  "LiftRight verification code",
  "<p>Your LiftRight verification code is:</p>
   <h2 style='letter-spacing:2px'>{$otp}</h2>
   <p>This code expires in 15 minutes.</p>"
);

auth_log($mysqli, $user_id, 'email_verify_sent', [
  'mode' => 'existing_user',
  'email' => (string)$u['email']
]);

if (!$sent) {
  $_SESSION['dev_verify_otp'] = $otp;
  echo json_encode([
    'success' => true,
    'message' => 'DEV: OTP generated (Brevo not configured).',
    'dev_otp' => $otp
  ]);
  exit;
}

echo json_encode(['success' => true, 'message' => 'OTP sent.']);
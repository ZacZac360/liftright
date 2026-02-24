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

/**
 * NEW FLOW: pending registration verification
 */
$pending_id = (int)($_SESSION['pre_verify_pending_id'] ?? 0);
if ($pending_id <= 0) {
  http_response_code(401);
  echo json_encode(['success' => false, 'message' => 'No verification session. Please register again.']);
  exit;
}

// Load pending registration
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
  http_response_code(404);
  echo json_encode(['success' => false, 'message' => 'Pending registration not found. Please register again.']);
  exit;
}

// Cooldown: 1 OTP per 60s (based on email_verifications for this pending_id)
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

// Generate OTP
$otp  = str_pad((string)random_int(0, 999999), 6, '0', STR_PAD_LEFT);
$hash = password_hash($otp, PASSWORD_DEFAULT);

// Invalidate old unused codes + insert new (transaction)
$mysqli->begin_transaction();
try {
  $stmt = $mysqli->prepare("
    UPDATE email_verifications
    SET consumed_at = NOW()
    WHERE pending_id = ? AND consumed_at IS NULL
  ");
  $stmt->bind_param("i", $pending_id);
  $stmt->execute();
  $stmt->close();

  $ttl = 900; // 15 min
  $stmt = $mysqli->prepare("
    INSERT INTO email_verifications (pending_id, token_hash, expires_at)
    VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? SECOND))
  ");
  $stmt->bind_param("isi", $pending_id, $hash, $ttl);
  $stmt->execute();
  $stmt->close();

  $mysqli->commit();
} catch (Throwable $e) {
  $mysqli->rollback();
  http_response_code(500);
  echo json_encode(['success' => false, 'message' => 'Server error. Please try again.']);
  exit;
}

// Brevo sender (keep simple; returns boolean)
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

$sent = brevo_send_email(
  (string)$p['email'],
  (string)$p['full_name'],
  "LiftRight verification code",
  "<p>Your LiftRight verification code is:</p>
   <h2 style='letter-spacing:2px'>{$otp}</h2>
   <p>This code expires in 15 minutes.</p>"
);

if (!$sent) {
  $_SESSION['dev_verify_otp'] = $otp; // DEV fallback
  echo json_encode([
    'success' => true,
    'message' => 'DEV: OTP generated (Brevo not configured).',
    'dev_otp' => $otp
  ]);
  exit;
}

echo json_encode(['success' => true, 'message' => 'OTP sent.']);
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

$pending_id = (int)($_SESSION['pre_verify_pending_id'] ?? 0);
if ($pending_id <= 0) {
  http_response_code(401);
  echo json_encode(['success' => false, 'message' => 'No verification session. Please register again.']);
  exit;
}

$otp = preg_replace('/\D+/', '', (string)($_POST['otp'] ?? ''));
if (strlen($otp) !== 6) {
  echo json_encode(['success' => false, 'message' => 'Enter the 6-digit code.']);
  exit;
}

// Load pending record
$stmt = $mysqli->prepare("
  SELECT pending_id, full_name, email, password_hash, role, age,
         affiliation, credential_type, credential_ref, statement,
         proof_file, proof_mime
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
  echo json_encode(['success' => false, 'message' => 'Pending registration not found. Please register again.']);
  exit;
}

// Get latest active OTP for this pending_id
$stmt = $mysqli->prepare("
  SELECT verif_id, token_hash, expires_at
  FROM email_verifications
  WHERE pending_id = ?
    AND consumed_at IS NULL
  ORDER BY created_at DESC
  LIMIT 1
");
$stmt->bind_param("i", $pending_id);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$row) {
  echo json_encode(['success' => false, 'message' => 'No active code found. Please resend.']);
  exit;
}

// expired?
if (strtotime((string)$row['expires_at']) < time()) {
  $vid = (int)$row['verif_id'];
  $stmt = $mysqli->prepare("UPDATE email_verifications SET consumed_at = NOW() WHERE verif_id=?");
  $stmt->bind_param("i", $vid);
  $stmt->execute();
  $stmt->close();

  echo json_encode(['success' => false, 'message' => 'Code expired. Please resend.']);
  exit;
}

// wrong?
if (!password_verify($otp, (string)$row['token_hash'])) {
  echo json_encode(['success' => false, 'message' => 'Incorrect code.']);
  exit;
}

$vid = (int)$row['verif_id'];

// Create real user now + consume otp + delete pending
$mysqli->begin_transaction();

try {
  // Ensure email not already in users (race safety)
  $stmt = $mysqli->prepare("SELECT user_id FROM users WHERE email = ? LIMIT 1");
  $stmt->bind_param("s", $p['email']);
  $stmt->execute();
  $exists = $stmt->get_result()->fetch_assoc();
  $stmt->close();

  if ($exists) {
    throw new Exception("That email is already registered. Try logging in.");
  }

  // consume the verified OTP
  $stmt = $mysqli->prepare("UPDATE email_verifications SET consumed_at = NOW() WHERE verif_id=?");
  $stmt->bind_param("i", $vid);
  $stmt->execute();
  $stmt->close();

  // consume ALL other unused OTPs for this pending_id (extra safe)
  $stmt = $mysqli->prepare("
    UPDATE email_verifications
    SET consumed_at = NOW()
    WHERE pending_id = ? AND consumed_at IS NULL
  ");
  $stmt->bind_param("i", $pending_id);
  $stmt->execute();
  $stmt->close();

  // create users row (now verified)
  $stmt = $mysqli->prepare("
    INSERT INTO users (full_name, email, password_hash, role, age, account_status, twofa_enabled, email_verified_at)
    VALUES (?, ?, ?, ?, ?, 'pending', 0, NOW())
  ");

  $age = $p['age']; // may be null
  $stmt->bind_param("ssssi", $p['full_name'], $p['email'], $p['password_hash'], $p['role'], $age);
  $stmt->execute();
  $newUserId = (int)$stmt->insert_id;
  $stmt->close();

  // if trainer, create trainer_applications row (pending admin review)
  if ((string)$p['role'] === 'trainer') {
    $stmt = $mysqli->prepare("
      INSERT INTO trainer_applications
        (user_id, affiliation, credential_type, credential_ref, statement, proof_file, proof_mime, status)
      VALUES
        (?, ?, ?, ?, ?, ?, ?, 'pending')
    ");
    $stmt->bind_param(
      "issssss",
      $newUserId,
      $p['affiliation'],
      $p['credential_type'],
      $p['credential_ref'],
      $p['statement'],
      $p['proof_file'],
      $p['proof_mime']
    );
    $stmt->execute();
    $stmt->close();
  }

  // delete pending record
  $stmt = $mysqli->prepare("DELETE FROM pending_registrations WHERE pending_id = ? LIMIT 1");
  $stmt->bind_param("i", $pending_id);
  $stmt->execute();
  $stmt->close();

  $mysqli->commit();

  unset($_SESSION['pre_verify_pending_id'], $_SESSION['dev_verify_otp']);
  echo json_encode(['success' => true, 'message' => 'Email verified.']);
  exit;

} catch (Throwable $e) {
  $mysqli->rollback();
  http_response_code(500);
  echo json_encode(['success' => false, 'message' => $e->getMessage()]);
  exit;
}
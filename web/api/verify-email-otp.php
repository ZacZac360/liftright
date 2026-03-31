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

$otp = preg_replace('/\D+/', '', (string)($_POST['otp'] ?? ''));
if (strlen($otp) !== 6) {
  echo json_encode(['success' => false, 'message' => 'Enter the 6-digit code.']);
  exit;
}

$pending_id = (int)($_SESSION['pre_verify_pending_id'] ?? 0);
$user_id    = (int)($_SESSION['pre_verify_user_id'] ?? 0);

if ($pending_id <= 0 && $user_id <= 0) {
  http_response_code(401);
  echo json_encode(['success' => false, 'message' => 'No verification session.']);
  exit;
}

/* =========================================================
   EXISTING USER FLOW
========================================================= */
if ($user_id > 0) {
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
    echo json_encode(['success' => false, 'message' => 'User not found.']);
    exit;
  }

  $result = verify_active_email_otp_for_user($mysqli, $user_id, $otp);

  if (!$result['ok']) {
    auth_log($mysqli, $user_id, 'email_verify_fail', [
      'mode' => 'existing_user',
      'reason' => $result['reason']
    ]);

    $msg = match ($result['reason']) {
      'expired' => 'Code expired. Please resend.',
      'invalid' => 'Incorrect code.',
      default   => 'No active code found. Please resend.',
    };

    echo json_encode(['success' => false, 'message' => $msg]);
    exit;
  }

  mark_user_email_verified($mysqli, $user_id);

  auth_log($mysqli, $user_id, 'email_verify_success', [
    'mode' => 'existing_user'
  ]);

  unset($_SESSION['pre_verify_user_id'], $_SESSION['dev_verify_otp']);

  echo json_encode([
    'success' => true,
    'message' => 'Email verified.',
    'redirect' => $BASE_URL . '/login.php?ok=' . urlencode('Email verified. You can now log in.')
  ]);
  exit;
}

/* =========================================================
   PENDING REGISTRATION FLOW
========================================================= */
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

$result = verify_active_email_otp_for_pending($mysqli, $pending_id, $otp);

if (!$result['ok']) {
  auth_log($mysqli, null, 'email_verify_fail', [
    'mode' => 'pending_registration',
    'pending_id' => $pending_id,
    'email' => (string)$p['email'],
    'reason' => $result['reason']
  ]);

  $msg = match ($result['reason']) {
    'expired' => 'Code expired. Please resend.',
    'invalid' => 'Incorrect code.',
    default   => 'No active code found. Please resend.',
  };

  echo json_encode(['success' => false, 'message' => $msg]);
  exit;
}

$mysqli->begin_transaction();

try {
  $stmt = $mysqli->prepare("SELECT user_id FROM users WHERE email = ? LIMIT 1");
  $stmt->bind_param("s", $p['email']);
  $stmt->execute();
  $exists = $stmt->get_result()->fetch_assoc();
  $stmt->close();

  if ($exists) {
    throw new Exception("That email is already registered. Try logging in.");
  }

  $stmt = $mysqli->prepare("
    INSERT INTO users (full_name, email, password_hash, role, age, account_status, twofa_enabled, email_verified_at)
    VALUES (?, ?, ?, ?, ?, 'pending', 0, NOW())
  ");
  $age = $p['age'];
  $stmt->bind_param("ssssi", $p['full_name'], $p['email'], $p['password_hash'], $p['role'], $age);
  $stmt->execute();
  $newUserId = (int)$stmt->insert_id;
  $stmt->close();

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

  $stmt = $mysqli->prepare("DELETE FROM pending_registrations WHERE pending_id = ? LIMIT 1");
  $stmt->bind_param("i", $pending_id);
  $stmt->execute();
  $stmt->close();

  $mysqli->commit();

  auth_log($mysqli, $newUserId, 'email_verify_success', [
    'mode' => 'pending_registration',
    'pending_id' => $pending_id
  ]);

  unset($_SESSION['pre_verify_pending_id'], $_SESSION['dev_verify_otp']);

  echo json_encode([
    'success' => true,
    'message' => 'Email verified. Awaiting admin approval.',
    'redirect' => $BASE_URL . '/login.php?status=pending'
  ]);
  exit;

} catch (Throwable $e) {
  $mysqli->rollback();

  auth_log($mysqli, null, 'email_verify_fail', [
    'mode' => 'pending_registration',
    'pending_id' => $pending_id,
    'email' => (string)$p['email'],
    'reason' => 'exception',
    'message' => $e->getMessage()
  ]);

  http_response_code(500);
  echo json_encode(['success' => false, 'message' => $e->getMessage()]);
  exit;
}
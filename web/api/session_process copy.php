<?php
// liftright/web/api/session_process.php
session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

header('Content-Type: application/json');

require_role(['user']); // trainee user

$input = json_decode(file_get_contents('php://input'), true) ?: [];
$action = (string)($input['action'] ?? '');

$user_id = (int)($_SESSION['user_id'] ?? 0);

function json_fail(string $msg, int $code = 400): void {
  http_response_code($code);
  echo json_encode(['success' => false, 'message' => $msg]);
  exit;
}

// where your Python realtime server runs
define('PY_SERVER', "http://127.0.0.1:5101");

function http_post_json(string $url, array $payload): array {
  $ch = curl_init($url);
  curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST => true,
    CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
    CURLOPT_POSTFIELDS => json_encode($payload),
    CURLOPT_TIMEOUT => 3,
  ]);
  $raw = curl_exec($ch);
  $err = curl_error($ch);
  $code = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
  curl_close($ch);

  if ($raw === false) return ['ok' => false, 'error' => $err ?: 'curl failed', 'http' => $code];
  $data = json_decode($raw, true);
  return ['ok' => ($code >= 200 && $code < 300), 'http' => $code, 'data' => $data, 'raw' => $raw];
}

$exercise = (string)($input['exercise_type'] ?? '');
$allowedExercises = ['bicep_curl','shoulder_press','lateral_raise'];
if ($exercise !== '' && !in_array($exercise, $allowedExercises, true)) {
  json_fail("Invalid exercise_type.");
}

if ($action === 'start') {
  // create a DB log row immediately (webcam source)
  $stmt = $mysqli->prepare("
    INSERT INTO training_logs (user_id, exercise_type, source_type, started_at)
    VALUES (?, ?, 'webcam', NOW())
  ");
  $stmt->bind_param("is", $user_id, $exercise);
  $stmt->execute();
  $log_id = (int)$stmt->insert_id;
  $stmt->close();

  // start python session
  $resp = http_post_json(PY_SERVER . "/start", [
    'exercise_type' => $exercise,
    'log_id' => $log_id,
    'user_id' => $user_id
  ]);

  if (!$resp['ok'] || empty($resp['data']['session_token'])) {
    // cleanup DB log if python failed
    $mysqli->query("DELETE FROM training_logs WHERE log_id = {$log_id} AND user_id = {$user_id}");
    json_fail("Python service not reachable. Start it first.", 500);
  }

  echo json_encode([
    'success' => true,
    'log_id' => $log_id,
    'session_token' => (string)$resp['data']['session_token']
  ]);
  exit;
}

if ($action === 'frame') {
  $log_id = (int)($input['log_id'] ?? 0);
  $token  = (string)($input['session_token'] ?? '');
  $frame  = (string)($input['frame_dataurl'] ?? '');

  if ($log_id <= 0 || $token === '' || $frame === '') json_fail("Missing frame payload.");

  // forward to python
  $resp = http_post_json(PY_SERVER . "/frame", [
    'session_token' => $token,
    'frame_dataurl' => $frame
  ]);

  if (!$resp['ok'] || !is_array($resp['data'])) {
    json_fail("Python frame processing failed.", 500);
  }

  // return the python result directly to browser
  echo json_encode(['success' => true] + $resp['data']);
  exit;
}

if ($action === 'finish') {
  $log_id = (int)($input['log_id'] ?? 0);
  $token  = (string)($input['session_token'] ?? '');
  if ($log_id <= 0 || $token === '') json_fail("Missing finish payload.");

  $t0 = microtime(true);

  // finalize python session and get rep + feedback summaries
  $resp = http_post_json(PY_SERVER . "/finish", [
    'session_token' => $token
  ]);

  if (!$resp['ok'] || !is_array($resp['data'])) {
    json_fail("Python finish failed.", 500);
  }

  $data = $resp['data'];

  // expected keys:
  // reps_total, reps_good, reps_bad, form_error_count, fatigue_flag
  // reps: [{rep_index,duration_ms,rom_score,trunk_sway,confidence_avg,form_label,anomaly_score}]
  // feedback: [{feedback_type,severity,feedback_text}]
  $processing_ms = (int)round((microtime(true) - $t0) * 1000);

  // update training_logs summary
  $stmt = $mysqli->prepare("
    UPDATE training_logs
    SET
      reps_total = ?, reps_good = ?, reps_bad = ?, form_error_count = ?, fatigue_flag = ?,
      finished_at = NOW(),
      processing_ms = ?
    WHERE log_id = ? AND user_id = ?
    LIMIT 1
  ");
  $reps_total = (int)($data['reps_total'] ?? 0);
  $reps_good  = (int)($data['reps_good'] ?? 0);
  $reps_bad   = (int)($data['reps_bad'] ?? 0);
  $err_count  = (int)($data['form_error_count'] ?? 0);
  $fatigue    = (int)($data['fatigue_flag'] ?? 0);

  $stmt->bind_param("iiiiiiii",
    $reps_total, $reps_good, $reps_bad, $err_count, $fatigue,
    $processing_ms, $log_id, $user_id
  );
  $stmt->execute();
  $stmt->close();

  // ... inside action === 'finish'

    if (!empty($data['reps']) && is_array($data['reps'])) {
      // (optional but recommended during dev)
      // mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

      $sql = "
        INSERT INTO rep_metrics
          (log_id, rep_index, duration_ms, rom_score, trunk_sway, confidence_avg, form_label, anomaly_score, rep_meta)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          duration_ms=VALUES(duration_ms),
          rom_score=VALUES(rom_score),
          trunk_sway=VALUES(trunk_sway),
          confidence_avg=VALUES(confidence_avg),
          form_label=VALUES(form_label),
          anomaly_score=VALUES(anomaly_score),
          rep_meta=VALUES(rep_meta)
      ";

      $stmt = $mysqli->prepare($sql);
      if (!$stmt) json_fail("rep_metrics prepare failed: " . $mysqli->error, 500);

      foreach ($data['reps'] as $r) {
        $rep_index = (int)($r['rep_index'] ?? 0);
        if ($rep_index <= 0) continue;

        $duration = (int)($r['duration_ms'] ?? 0);
        $rom      = (float)($r['rom_score'] ?? 0.0);
        $sway     = (float)($r['trunk_sway'] ?? 0.0);
        $conf     = (float)($r['confidence_avg'] ?? 0.0);
        $label    = (string)($r['form_label'] ?? 'unknown');
        $score    = (float)($r['anomaly_score'] ?? 0.0);

        $metaJson = "";
        if (!empty($r['meta']) && is_array($r['meta'])) {
          $metaJson = json_encode($r['meta'], JSON_UNESCAPED_SLASHES);
        }

        // 9 params: i i i d d d s d s
        $ok = $stmt->bind_param(
          "iiidddsds",
          $log_id, $rep_index, $duration,
          $rom, $sway, $conf,
          $label,
          $score,
          $metaJson
        );

        if (!$ok) json_fail("rep_metrics bind_param failed: " . $stmt->error, 500);
        if (!$stmt->execute()) json_fail("rep_metrics execute failed: " . $stmt->error, 500);
      }

      $stmt->close();
    }
  
    if (!empty($data['feedback']) && is_array($data['feedback'])) {
    $stmt = $mysqli->prepare("
      INSERT INTO feedback (log_id, feedback_type, severity, feedback_text, feedback_meta)
      VALUES (?, ?, ?, ?, ?)
    ");

    foreach ($data['feedback'] as $f) {
      $type = (string)($f['feedback_type'] ?? 'posture');
      $sev  = (string)($f['severity'] ?? 'info');
      $txt  = (string)($f['feedback_text'] ?? '');
      if ($txt === '') continue;

      $metaJson = null;
      if (!empty($f['meta']) && is_array($f['meta'])) {
        $metaJson = json_encode($f['meta'], JSON_UNESCAPED_SLASHES);
      }

      $stmt->bind_param("issss", $log_id, $type, $sev, $txt, $metaJson);
      if (!$stmt->execute()) json_fail("feedback execute failed: " . $stmt->error, 500);
    }
    $stmt->close();
  }


  echo json_encode(['success' => true, 'log_id' => $log_id]);
  exit;
}

json_fail("Unknown action.");

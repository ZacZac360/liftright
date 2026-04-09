<?php
// liftright/web/api/session_process.php
session_start();

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

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

function save_dataurl_image(string $dataurl, string $absDir, string $baseName): ?array {
  if (!preg_match('#^data:image/(jpeg|jpg|png);base64,#i', $dataurl, $m)) {
    return null;
  }

  $ext = strtolower($m[1]);
  if ($ext === 'jpeg') $ext = 'jpg';

  $commaPos = strpos($dataurl, ',');
  if ($commaPos === false) return null;

  $bin = base64_decode(substr($dataurl, $commaPos + 1), true);
  if ($bin === false) return null;

  if (!is_dir($absDir) && !mkdir($absDir, 0775, true) && !is_dir($absDir)) {
    return null;
  }

  $fileName = $baseName . '.' . $ext;
  $absPath = rtrim($absDir, '/\\') . DIRECTORY_SEPARATOR . $fileName;

  if (file_put_contents($absPath, $bin) === false) {
    return null;
  }

  return [
    'ext' => $ext,
    'file_name' => $fileName,
    'abs_path' => $absPath
  ];
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

if ($action === 'gate') {
  $frame  = (string)($input['frame_dataurl'] ?? '');
  if ($frame === '') json_fail("Missing gate frame payload.");

  $resp = http_post_json(PY_SERVER . "/gate", [
    'frame_dataurl' => $frame
  ]);

  if (!$resp['ok'] || !is_array($resp['data'])) {
    json_fail("Python gate failed.", 500);
  }

  echo json_encode(['success' => true] + $resp['data']);
  exit;
}

if ($action === 'rep_screenshot') {
  $log_id = (int)($input['log_id'] ?? 0);
  $rep_index = (int)($input['rep_index'] ?? 0);
  $token = (string)($input['session_token'] ?? '');
  $image_dataurl = (string)($input['image_dataurl'] ?? '');

  if ($log_id <= 0 || $rep_index <= 0 || $token === '' || $image_dataurl === '') {
    json_fail("Missing screenshot payload.");
  }

  // Verify the session log belongs to the current user
  $stmt = $mysqli->prepare("
    SELECT log_id
    FROM training_logs
    WHERE log_id = ? AND user_id = ?
    LIMIT 1
  ");
  $stmt->bind_param("ii", $log_id, $user_id);
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
  $stmt->close();

  if (!$row) {
    json_fail("Invalid log_id.", 403);
  }

  $relativeDir = "uploads/rep_snapshots/log_" . $log_id;
  $absoluteDir = __DIR__ . "/../" . $relativeDir;

  $saved = save_dataurl_image($image_dataurl, $absoluteDir, "rep_" . $rep_index);
  if (!$saved) {
    json_fail("Failed to save screenshot.", 500);
  }

  $relativePath = $relativeDir . "/" . $saved['file_name'];

  $stmt = $mysqli->prepare("
    INSERT INTO rep_snapshots (log_id, rep_index, image_path, captured_at)
    VALUES (?, ?, ?, NOW())
    ON DUPLICATE KEY UPDATE
      image_path = VALUES(image_path),
      captured_at = NOW()
  ");
  $stmt->bind_param("iis", $log_id, $rep_index, $relativePath);
  $stmt->execute();
  $stmt->close();

  echo json_encode([
    'success' => true,
    'log_id' => $log_id,
    'rep_index' => $rep_index,
    'image_path' => $relativePath
  ]);
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
      reps_total = ?,
      reps_good = ?,
      reps_bad = ?,
      form_error_count = ?,
      fatigue_flag = ?,
      fatigue_peak_score = ?,
      fatigue_final_score = ?,
      fatigue_level = ?,
      fatigue_trend = ?,
      fatigue_since_rep = ?,
      fatigue_summary = ?,
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

  $fatigue_peak_score  = (float)($data['fatigue_peak_score'] ?? 0);
  $fatigue_final_score = (float)($data['fatigue_final_score'] ?? 0);
  $fatigue_level       = (string)($data['fatigue_level'] ?? 'none');
  $fatigue_trend       = (string)($data['fatigue_trend'] ?? 'stable');
  $fatigue_since_rep   = !empty($data['fatigue_since_rep']) ? (int)$data['fatigue_since_rep'] : null;
  $fatigue_summary     = (string)($data['fatigue_summary'] ?? '');

  $stmt->bind_param(
    "iiiiiddssisiii",
    $reps_total,
    $reps_good,
    $reps_bad,
    $err_count,
    $fatigue,
    $fatigue_peak_score,
    $fatigue_final_score,
    $fatigue_level,
    $fatigue_trend,
    $fatigue_since_rep,
    $fatigue_summary,
    $processing_ms,
    $log_id,
    $user_id
  );
  $stmt->execute();
  $stmt->close();

  // ... inside action === 'finish'

    if (!empty($data['reps']) && is_array($data['reps'])) {
      // (optional but recommended during dev)
      // mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

      $sql = "
        INSERT INTO rep_metrics
          (
            log_id,
            rep_index,
            duration_ms,
            rom_score,
            trunk_sway,
            confidence_avg,
            form_label,
            anomaly_score,
            fatigue_score,
            fatigue_level,
            fatigue_trend,
            rep_meta
          )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          duration_ms = VALUES(duration_ms),
          rom_score = VALUES(rom_score),
          trunk_sway = VALUES(trunk_sway),
          confidence_avg = VALUES(confidence_avg),
          form_label = VALUES(form_label),
          anomaly_score = VALUES(anomaly_score),
          fatigue_score = VALUES(fatigue_score),
          fatigue_level = VALUES(fatigue_level),
          fatigue_trend = VALUES(fatigue_trend),
          rep_meta = VALUES(rep_meta)
      ";

      $stmt = $mysqli->prepare($sql);
      if (!$stmt) json_fail("rep_metrics prepare failed: " . $mysqli->error, 500);

      foreach ($data['reps'] as $r) {
        $rep_index = (int)($r['rep_index'] ?? 0);
        if ($rep_index <= 0) continue;

        $duration      = (int)($r['duration_ms'] ?? 0);
        $rom           = (float)($r['rom_score'] ?? 0.0);
        $sway          = (float)($r['trunk_sway'] ?? 0.0);
        $conf          = (float)($r['confidence_avg'] ?? 0.0);
        $label         = (string)($r['form_label'] ?? 'unknown');
        $score         = (float)($r['anomaly_score'] ?? 0.0);
        $fatigue_score = (float)($r['fatigue_score'] ?? 0.0);
        $fatigue_level = (string)($r['fatigue_level'] ?? 'none');
        $fatigue_trend = (string)($r['fatigue_trend'] ?? 'stable');

        $metaJson = "";
        if (!empty($r['meta']) && is_array($r['meta'])) {
          $metaJson = json_encode($r['meta'], JSON_UNESCAPED_SLASHES);
        }

        // 12 params: i i i d d d s d d s s s
        $ok = $stmt->bind_param(
          "iiidddsddsss",
          $log_id,
          $rep_index,
          $duration,
          $rom,
          $sway,
          $conf,
          $label,
          $score,
          $fatigue_score,
          $fatigue_level,
          $fatigue_trend,
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

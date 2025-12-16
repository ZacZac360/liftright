<?php
// liftright/web/api/dashboard_trend.php
session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

header('Content-Type: application/json');
require_role(['user']);

$user_id = (int)($_SESSION['user_id'] ?? 0);

function json_fail(string $msg, int $code = 400): void {
  http_response_code($code);
  echo json_encode(['success' => false, 'message' => $msg]);
  exit;
}

$points = [];
$stmt = $mysqli->prepare("
  SELECT log_id, created_at, reps_total, reps_good, fatigue_flag
  FROM training_logs
  WHERE user_id = ?
    AND finished_at IS NOT NULL
    AND reps_total >= 1
  ORDER BY created_at ASC
  LIMIT 10
");

$stmt->bind_param("i", $user_id);
$stmt->execute();
$res = $stmt->get_result();
while ($r = $res->fetch_assoc()) {
  $total = (int)($r['reps_total'] ?? 0);
  $good  = (int)($r['reps_good'] ?? 0);
  $pct   = ($total > 0) ? round(($good / $total) * 100, 2) : 0;

  $points[] = [
    'log_id' => (int)$r['log_id'],
    'label'  => date("M d", strtotime((string)$r['created_at'])),
    'pct'    => $pct,
    'fatigue'=> (int)($r['fatigue_flag'] ?? 0),
  ];
}
$stmt->close();

// reverse so chart goes oldest -> newest
$points = array_reverse($points);

echo json_encode(['success' => true, 'points' => $points]);

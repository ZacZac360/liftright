<?php
// liftright/web/api/dashboard_trend.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

header('Content-Type: application/json');

if (!isset($_SESSION['user_id'])) {
  echo json_encode([
    'success' => false,
    'message' => 'Unauthorized.'
  ]);
  exit;
}

$user_id = (int)$_SESSION['user_id'];

$stmt = $mysqli->prepare("
  SELECT
    log_id,
    created_at,
    reps_good,
    reps_total,
    fatigue_flag
  FROM training_logs
  WHERE user_id = ?
  ORDER BY created_at DESC
  LIMIT 10
");

$stmt->bind_param("i", $user_id);
$stmt->execute();
$res = $stmt->get_result();

$rows = [];
while ($row = $res->fetch_assoc()) {
  $rows[] = $row;
}
$stmt->close();

/*
  We fetch newest first for SQL simplicity,
  then reverse so the chart reads left -> right chronologically.
*/
$rows = array_reverse($rows);

$points = [];
foreach ($rows as $row) {
  $total = (int)($row['reps_total'] ?? 0);
  $good  = (int)($row['reps_good'] ?? 0);
  $pct   = ($total > 0) ? (int)round(($good / $total) * 100) : 0;

  $ts = strtotime((string)$row['created_at']);

  $points[] = [
    'log_id'   => (int)$row['log_id'],
    'pct'      => $pct,
    'fatigue'  => (int)($row['fatigue_flag'] ?? 0),
    'label'    => $ts ? date('M d', $ts) : '—',
    'full_label' => $ts ? date('M d, Y • g:i A', $ts) : '—',
    'created_at' => (string)$row['created_at'],
  ];
}

echo json_encode([
  'success' => true,
  'points'  => $points
]);
<?php
session_start();
require_once __DIR__ . "/config/config.php";

$role = $_SESSION['role'] ?? null;

if (!$role) {
  header("Location: {$BASE_URL}/login.php");
  exit;
}

if ($role === 'user') {
  header("Location: {$BASE_URL}/trainee/dashboard.php");
  exit;
}

if ($role === 'trainer') {
  header("Location: {$BASE_URL}/coach/dashboard.php");
  exit;
}

if ($role === 'admin') {
  header("Location: {$BASE_URL}/admin/dashboard.php");
  exit;
}

// unknown role
header("Location: {$BASE_URL}/logout.php");
exit;

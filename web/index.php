<?php
// index.php - simple redirect based on session
session_start();
require_once __DIR__ . '/config/config.php';

if (isset($_SESSION['role'])) {
    if ($_SESSION['role'] === 'trainee') {
        header("Location: {$BASE_URL}/trainee/dashboard.php");
        exit;
    } elseif ($_SESSION['role'] === 'coach') {
        header("Location: {$BASE_URL}/coach/dashboard.php");
        exit;
    } else {
        header("Location: {$BASE_URL}/admin/dashboard.php");
        exit;
    }
} else {
    header("Location: {$BASE_URL}/login.php");
    exit;
}

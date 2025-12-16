<?php
// liftright/web/config/config.php

declare(strict_types=1);

$BASE_URL = "/liftright/web"; // since htdocs/liftright/web is your root

// DB config (XAMPP defaults)
define('DB_HOST', '127.0.0.1');
define('DB_USER', 'root');
define('DB_PASS', 'Pokemon2003');              // XAMPP default usually blank
define('DB_NAME', 'liftright_db');
define('DB_PORT', 3306);

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
  $mysqli = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME, DB_PORT);
  $mysqli->set_charset('utf8mb4');
} catch (Throwable $e) {
  http_response_code(500);
  echo "DB connection failed.";
  exit;
}

function h(string $s): string {
  return htmlspecialchars($s, ENT_QUOTES, 'UTF-8');
}

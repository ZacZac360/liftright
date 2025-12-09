<?php
// config/config.php - central app configuration and DB connection

// Adjust this to match your local setup
$DB_HOST = "localhost";
$DB_USER = "root";
$DB_PASS = "Pokemon2003";
$DB_NAME = "liftright";

// Base URL of the app
$BASE_URL = "http://localhost/liftright";

// Create mysqli connection
$mysqli = new mysqli($DB_HOST, $DB_USER, $DB_PASS, $DB_NAME);

if ($mysqli->connect_error) {
    die("Database connection failed: " . $mysqli->connect_error);
}

// Optional: set charset
$mysqli->set_charset("utf8mb4");

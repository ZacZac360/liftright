<?php
// liftright/web/includes/head.php
if (!isset($page_title)) $page_title = "LiftRight";
global $BASE_URL;
?>
<!doctype html>
<html lang="en" data-theme="<?= h($_SESSION['theme'] ?? 'default') ?>">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><?= h($page_title) ?></title>
  <link rel="icon" type="image/x-icon" href="/liftright/web/favicon.ico">

  <!-- Let JS read BASE_URL safely -->
  <meta name="lr-base-url" content="<?= h($BASE_URL) ?>">

  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" rel="stylesheet">

  <link href="<?= $BASE_URL ?>/assets/css/style.css" rel="stylesheet">
</head>
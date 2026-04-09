<?php
session_start();
session_unset();
session_destroy();

header("Location: /liftright/web/index.php");
exit;

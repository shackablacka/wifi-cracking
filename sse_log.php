<?php
header('Content-Type: text/event-stream');
header('Cache-Control: no-cache');

$lastMod = 0;
while (true) {
    clearstatcache();
    $currentMod = filemtime("log.txt");
    if ($currentMod > $lastMod) {
        $lastMod = $currentMod;
        echo "data: " . str_replace(["\r", "\n"], ["", "\n"], file_get_contents("log.txt")) . "\n\n";
        ob_flush();
        flush();
    }
    sleep(1);
}
?>

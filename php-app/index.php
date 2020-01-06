<?php

$mysqli = extension_loaded('mysqli');

if (!$mysqli) {
    echo "Laravel requires Mysqli";
} else {
    echo "Mysqli is loaded";    
}


echo "<br>";

echo PHP_VERSION;

echo "<br>";

echo $_SERVER['API_ENDPOINT'];

echo "<br>";

echo 'memory limit: ' . ini_get('memory_limit');

echo "<br>";

echo 'upload_max_filesize: ' . ini_get('upload_max_filesize');

echo "<br>";

echo 'post_max_size: ' . ini_get('post_max_size');

echo "<br>";

echo 'max_execution_time: ' . ini_get('max_execution_time');

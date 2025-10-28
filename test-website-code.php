<?php
// Test script to check WEBSITE_CODE variable
header('Content-Type: application/json');

$result = [
    'WEBSITE_CODE' => $_SERVER['WEBSITE_CODE'] ?? 'NOT_SET',
    'WEBSITE_PATH' => $_SERVER['WEBSITE_PATH'] ?? 'NOT_SET',
    'REQUEST_URI' => $_SERVER['REQUEST_URI'] ?? 'NOT_SET',
    'HTTP_X_WEBSITE_CODE' => $_SERVER['HTTP_X_WEBSITE_CODE'] ?? 'NOT_SET',
    'all_server_vars' => array_filter($_SERVER, function($key) {
        return strpos($key, 'WEBSITE') !== false || strpos($key, 'HTTP_X') !== false;
    }, ARRAY_FILTER_USE_KEY)
];

echo json_encode($result, JSON_PRETTY_PRINT);
?>

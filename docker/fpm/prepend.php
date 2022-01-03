<?php

if (PHP_SAPI === 'fpm-fcgi') {
    $_SERVER['REMOTE_ADDR'] = "127.0.0.1";
}

<?php
declare(strict_types=1);

if (!function_exists('lr_snippet')) {
  function lr_snippet(string $s, int $max = 70): string {
    $s = trim(preg_replace('/\s+/', ' ', $s));
    if (mb_strlen($s) <= $max) return $s;
    return mb_substr($s, 0, $max - 1) . '…';
  }
}
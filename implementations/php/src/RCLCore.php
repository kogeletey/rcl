<?php
require_once __DIR__ . '/RCLAst.php';

final class RCLCore {
  public static function parse(string $text): array { return RCLAst::parse($text); }
  public static function toObject(string $text): array { return RCLAst::project(self::parse($text)); }
}

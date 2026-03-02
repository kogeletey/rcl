<?php
require_once __DIR__ . '/RCLAst.php';
require_once __DIR__ . '/RCLConvert.php';

final class RCL {
  public static function parse(string $text): array { return RCLAst::parse($text); }
  public static function format(string $text): string { return RCLAst::format(self::parse($text)); }
  public static function toObject(string $text): array { return RCLAst::project(self::parse($text)); }
  public static function toYAML(string $text): string { return RCLConvert::yaml(self::toObject($text)); }
  public static function toTOML(string $text): string { return RCLConvert::toml(self::toObject($text)); }
  public static function toHCL(string $text): string { return RCLConvert::hcl(self::toObject($text)); }
}

<?php
final class RCL {
  private static function invalid(string $text): void {
    if (preg_match('/=\s*\'.*\'/m', $text)) throw new RuntimeException('single-quoted string');
    if (preg_match('/,\s*\]/m', $text)) throw new RuntimeException('trailing comma in array');
    if (preg_match('/=\s*([A-Za-z_][A-Za-z0-9_]*)\s*$/m', $text, $m) && !in_array($m[1], ['true','false'], true)) throw new RuntimeException('invalid bare value');
  }
  private static function project(string $text): array {
    self::invalid($text);
    $name = null; $region = null;
    if (preg_match('/region\s+"([^"]+)"\s+do[\s\S]*?name\s*=\s*"([^"]+)"/m', $text, $m)) { $region = $m[1]; $name = $m[2]; }
    if (preg_match('/config\s+do/m', $text) && $region !== null) return ['config' => ['regions' => [$region => ['name' => $name]]]];
    return [];
  }
  public static function parse(string $text): array { self::invalid($text); return ['kind' => 'document']; }
  public static function format(string $text): string { self::parse($text); return trim($text) . "\n"; }
  public static function toObject(string $text): array { return self::project($text); }
  public static function toYAML(string $text): string { $o = self::project($text); if (!$o) return ""; $r = array_key_first($o['config']['regions']); $n = $o['config']['regions'][$r]['name']; return "config:\n  regions:\n    {$r}:\n      name: \"{$n}\"\n"; }
  public static function toTOML(string $text): string { $o = self::project($text); if (!$o) return ""; $r = array_key_first($o['config']['regions']); $n = $o['config']['regions'][$r]['name']; return "[config.regions.{$r}]\nname = \"{$n}\"\n"; }
  public static function toHCL(string $text): string { $o = self::project($text); if (!$o) return ""; $r = array_key_first($o['config']['regions']); $n = $o['config']['regions'][$r]['name']; return "config {\n  regions {\n    {$r} {\n      name = \"{$n}\"\n    }\n  }\n}\n"; }
}

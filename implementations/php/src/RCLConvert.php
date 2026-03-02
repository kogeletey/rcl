<?php

final class RCLConvert {
  public static function yaml(array $obj): string {
    return self::yamlMap($obj, 0);
  }
  public static function toml(array $obj): string {
    $lines = self::tomlTable($obj, []);
    return $lines === [] ? '' : implode("\n", $lines) . "\n";
  }
  public static function hcl(array $obj): string {
    if ($obj === []) return "{}\n";
    $s = '';
    foreach (self::entries($obj) as [$k, $v]) $s .= self::hclKey($k) . ' = ' . self::hclVal($v, 0) . "\n";
    return $s;
  }
  private static function yamlMap(array $m, int $n): string {
    if ($m === []) return str_repeat(' ', $n) . "{}\n";
    $s = '';
    foreach (self::entries($m) as [$k, $v]) {
      $i = str_repeat(' ', $n);
      if (is_array($v) && self::isAssoc($v)) $s .= $i . self::yamlKey($k) . ":\n" . self::yamlMap($v, $n + 2);
      else $s .= $i . self::yamlKey($k) . ': ' . self::yamlScalar($v) . "\n";
    }
    return $s;
  }
  private static function tomlTable(array $m, array $path): array {
    $lines = [];
    if ($path !== []) $lines[] = '[' . implode('.', array_map(fn($k) => self::tomlKey($k), $path)) . ']';
    $children = [];
    foreach (self::entries($m) as [$k, $v]) {
      if (is_array($v) && self::isAssoc($v)) $children[] = [$k, $v];
      else $lines[] = self::tomlKey($k) . ' = ' . self::tomlScalar($v);
    }
    foreach ($children as [$k, $v]) {
      $child = self::tomlTable($v, [...$path, $k]);
      if ($lines !== [] && end($lines) !== '') $lines[] = '';
      $lines = [...$lines, ...$child];
    }
    return $lines;
  }
  private static function hclVal(mixed $v, int $n): string {
    if (is_array($v) && self::isAssoc($v)) {
      if ($v === []) return '{}';
      $i = str_repeat(' ', $n);
      $s = "{\n";
      foreach (self::entries($v) as [$k, $x]) $s .= $i . '  ' . self::hclKey($k) . ' = ' . self::hclVal($x, $n + 2) . "\n";
      return $s . $i . '}';
    }
    return self::tomlScalar($v);
  }
  private static function tomlScalar(mixed $v): string {
    if (is_string($v)) return '"' . self::esc($v) . '"';
    if (is_bool($v)) return $v ? 'true' : 'false';
    if (is_array($v)) return '[' . implode(', ', array_map(fn($x) => self::tomlScalar($x), $v)) . ']';
    return (string)$v;
  }
  private static function yamlScalar(mixed $v): string {
    if (is_array($v)) return '[' . implode(', ', array_map(fn($x) => self::yamlScalar($x), $v)) . ']';
    return self::tomlScalar($v);
  }
  private static function esc(string $s): string {
    return str_replace(["\\", '"', "\n", "\t"], ["\\\\", '\\"', '\\n', '\\t'], $s);
  }
  private static function isAssoc(array $a): bool { return array_keys($a) !== range(0, count($a) - 1); }
  private static function entries(array $m): array { ksort($m); $out = []; foreach ($m as $k => $v) $out[] = [(string)$k, $v]; return $out; }
  private static function bare(string $k): bool { return preg_match('/^[A-Za-z_][A-Za-z0-9_]*$/', $k) === 1; }
  private static function tomlKey(string $k): string { return self::bare($k) ? $k : '"' . self::esc($k) . '"'; }
  private static function yamlKey(string $k): string { return self::bare($k) ? $k : '"' . self::esc($k) . '"'; }
  private static function hclKey(string $k): string { return self::bare($k) ? $k : '"' . self::esc($k) . '"'; }
}

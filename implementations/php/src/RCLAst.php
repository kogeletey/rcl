<?php
require_once __DIR__ . '/RCLLexer.php';
require_once __DIR__ . '/RCLParser.php';

final class RCLParseError extends RuntimeException {}

final class RCLAst {
  public static function parse(string $src): array {
    $lx = new RCLLexer($src);
    $p = new RCLParser($lx);
    return $p->program();
  }
  public static function format(array $ast): string {
    if (isset($ast['rootValue']) && is_array($ast['rootValue']) && ($ast['rootValue']['type'] ?? null) === 'array') {
      return 'do ' . self::fmtVal($ast['rootValue']);
    }
    $out = '';
    foreach ($ast['blocks'] as $b) $out .= self::fmtBlock($b, 0);
    return $out;
  }
  public static function project(array $ast): array {
    if (isset($ast['rootValue']) && is_array($ast['rootValue'])) return ['root' => self::value($ast['rootValue'])];
    $out = [];
    foreach ($ast['blocks'] as $b) self::mergeBlock($out, $b);
    return $out;
  }
  private static function fmtBlock(array $b, int $n): string {
    $i = str_repeat(' ', $n);
    $s = $i . $b['name'] . ($b['arg'] === null ? '' : ' "' . self::esc($b['arg']) . '"') . " do\n";
    foreach ($b['statements'] as $st) {
      if ($st['type'] === 'property') {
        if (($st['value']['type'] ?? null) === 'array') $s .= $i . '  ' . implode('.', $st['key']) . ' do ' . self::fmtVal($st['value']) . " end\n";
        else $s .= $i . '  ' . implode('.', $st['key']) . ' = ' . self::fmtVal($st['value']) . "\n";
      }
      else $s .= self::fmtBlock($st, $n + 2);
    }
    return $s . $i . "end\n";
  }
  private static function fmtVal(array $v): string {
    if ($v['type'] === 'string') return '"' . self::esc($v['value']) . '"';
    if ($v['type'] === 'number') return $v['raw'];
    if ($v['type'] === 'boolean') return $v['value'] ? 'true' : 'false';
    if ($v['type'] === 'block') return self::fmtAnon($v);
    return '[' . implode(', ', array_map(fn($x) => self::fmtVal($x), $v['items'])) . ']';
  }
  private static function esc(string $s): string { return str_replace(["\\", '"', "\n", "\t"], ["\\\\", '\\"', '\\n', '\\t'], $s); }
  private static function mergeBlock(array &$dst, array $b): void {
    $obj = self::projectBlock($b);
    if ($b['arg'] === null) self::mergeAt($dst, $b['name'], $obj);
    else {
      $base = self::base($b['name']);
      if (!isset($dst[$base]) || !is_array($dst[$base])) $dst[$base] = [];
      self::mergeAt($dst[$base], $b['arg'], $obj);
    }
  }
  private static function projectBlock(array $b): array {
    $o = [];
    foreach ($b['statements'] as $st) {
      if ($st['type'] === 'property') self::setPath($o, $st['key'], self::value($st['value']));
      else {
        $child = self::projectBlock($st);
        if ($st['arg'] === null) self::mergeAt($o, $st['name'], $child);
        else {
          $base = self::base($st['name']);
          if (!isset($o[$base]) || !is_array($o[$base])) $o[$base] = [];
          self::mergeAt($o[$base], $st['arg'], $child);
        }
      }
    }
    return $o;
  }
  private static function value(array $v): mixed {
    if ($v['type'] === 'array') return array_map(fn($x) => self::value($x), $v['items']);
    if ($v['type'] === 'block') return self::projectBlock($v);
    return $v['value'];
  }
  private static function setPath(array &$o, array $path, mixed $v): void {
    $k = array_shift($path);
    if ($path === []) $o[$k] = $v;
    else {
      if (!isset($o[$k]) || !is_array($o[$k])) $o[$k] = [];
      self::setPath($o[$k], $path, $v);
    }
  }
  private static function mergeAt(array &$o, string $k, array $v): void {
    if (!isset($o[$k]) || !is_array($o[$k])) $o[$k] = [];
    self::deepMerge($o[$k], $v);
  }
  private static function deepMerge(array &$a, array $b): void {
    foreach ($b as $k => $v) {
      if (isset($a[$k]) && is_array($a[$k]) && is_array($v)) self::deepMerge($a[$k], $v);
      else $a[$k] = $v;
    }
  }
  private static function fmtAnon(array $b): string {
    $parts = [];
    foreach ($b['statements'] as $st) {
      if ($st['type'] === 'property') $parts[] = implode('.', $st['key']) . ' = ' . self::fmtVal($st['value']);
      else $parts[] = self::fmtInline($st);
    }
    return $parts === [] ? 'do end' : 'do ' . implode(' ', $parts) . ' end';
  }
  private static function fmtInline(array $b): string {
    $head = $b['name'] . ($b['arg'] === null ? '' : ' "' . self::esc($b['arg']) . '"') . ' do';
    $parts = [];
    foreach ($b['statements'] as $st) {
      if ($st['type'] === 'property') $parts[] = implode('.', $st['key']) . ' = ' . self::fmtVal($st['value']);
      else $parts[] = self::fmtInline($st);
    }
    return $parts === [] ? $head . ' end' : $head . ' ' . implode(' ', $parts) . ' end';
  }
  private static function base(string $n): string { return str_ends_with($n, 's') ? $n : $n . 's'; }
}

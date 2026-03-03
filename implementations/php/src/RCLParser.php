<?php

final class RCLParser {
  private array $t;
  public function __construct(private RCLLexer $l) { $this->t = $l->next(); }
  public function program(): array {
    if ($this->t['type'] === 'do') {
      $this->eat('do');
      $rootValue = $this->value();
      if ($rootValue['type'] !== 'array') $this->fail('unexpected token', $this->t);
      if ($this->t['type'] !== 'eof') $this->fail('unexpected token after root array', $this->t);
      return ['type' => 'Document', 'blocks' => [], 'rootValue' => $rootValue];
    }
    $blocks = [];
    while ($this->t['type'] !== 'eof') $blocks[] = $this->block();
    return ['type' => 'Document', 'blocks' => $blocks];
  }
  private function block(): array {
    $name = $this->eat('id')['value'];
    $arg = $this->t['type'] === 'string' ? $this->eat('string')['value'] : null;
    $this->eat('do');
    $stmts = []; $keys = [];
    while ($this->t['type'] !== 'end') {
      if ($this->t['type'] === 'eof') $this->fail('missing end', $this->t);
      $stmts[] = $this->stmt($keys);
    }
    $this->eat('end');
    return ['type' => 'Block', 'name' => $name, 'arg' => $arg, 'statements' => $stmts];
  }
  private function stmt(array &$keys): array {
    $id = $this->eat('id');
    if ($this->t['type'] === 'do') {
      $this->eat('do');
      if ($this->t['type'] === '[') {
        $path = [$id['value']];
        $this->checkPath($keys, $path, $id);
        $value = $this->value();
        $this->eat('end');
        return ['type' => 'property', 'key' => $path, 'value' => $value];
      }
      $stmts = []; $inner = [];
      while ($this->t['type'] !== 'end') { if ($this->t['type'] === 'eof') $this->fail('missing end', $this->t); $stmts[] = $this->stmt($inner); }
      $this->eat('end');
      return ['type' => 'Block', 'name' => $id['value'], 'arg' => null, 'statements' => $stmts];
    }
    if ($this->t['type'] === 'string') {
      $arg = $this->t['type'] === 'string' ? $this->eat('string')['value'] : null;
      $this->eat('do');
      $stmts = []; $inner = [];
      while ($this->t['type'] !== 'end') { if ($this->t['type'] === 'eof') $this->fail('missing end', $this->t); $stmts[] = $this->stmt($inner); }
      $this->eat('end');
      return ['type' => 'Block', 'name' => $id['value'], 'arg' => $arg, 'statements' => $stmts];
    }
    $path = [$id['value']];
    while ($this->t['type'] === '.') { $this->eat('.'); $path[] = $this->eat('id')['value']; }
    $this->eat('=');
    $this->checkPath($keys, $path, $id);
    return ['type' => 'property', 'key' => $path, 'value' => $this->value()];
  }
  private function value(): array {
    $t = $this->t['type'];
    if ($t === 'string') { $x = $this->eat('string'); return ['type' => 'string', 'value' => $x['value']]; }
    if ($t === 'number') { $x = $this->eat('number'); return ['type' => 'number', 'value' => $x['value'], 'raw' => $x['raw']]; }
    if ($t === 'bool') { $x = $this->eat('bool'); return ['type' => 'boolean', 'value' => $x['value']]; }
    if ($t === '[') {
      $s = $this->eat('[');
      $items = [];
      if ($this->t['type'] !== ']') {
        while (true) {
          $items[] = $this->value();
          if ($this->t['type'] !== ',') break;
          $this->eat(',');
          if ($this->t['type'] === ']') $this->fail('trailing comma in array', $this->t);
        }
      }
      if ($this->t['type'] !== ']') $this->fail('missing ]', $s);
      $this->eat(']');
      return ['type' => 'array', 'items' => $items];
    }
    if ($t === 'do') {
      $this->eat('do');
      $stmts = []; $inner = [];
      while ($this->t['type'] !== 'end') { if ($this->t['type'] === 'eof') $this->fail('missing end', $this->t); $stmts[] = $this->stmt($inner); }
      $this->eat('end');
      return ['type' => 'block', 'name' => '', 'arg' => null, 'statements' => $stmts];
    }
    if ($t === 'id') $this->fail('invalid bare identifier value', $this->t);
    $this->fail('unexpected token', $this->t);
  }
  private function checkPath(array &$keys, array $path, array $at): void {
    foreach ($keys as $k) if ($k === $path || $this->pref($k, $path) || $this->pref($path, $k)) $this->fail('duplicate or conflicting key path', $at);
    $keys[] = $path;
  }
  private function pref(array $a, array $b): bool {
    if (count($a) >= count($b)) return false;
    for ($i = 0; $i < count($a); $i++) if ($a[$i] !== $b[$i]) return false;
    return true;
  }
  private function eat(string $t): array { $x = $this->t; if ($x['type'] !== $t) $this->fail('unexpected token', $x); $this->t = $this->l->next(); return $x; }
  private function fail(string $m, array $t): never { throw new RCLParseError("line {$t['line']}, column {$t['col']}: $m"); }
}

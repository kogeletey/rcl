<?php

final class RCLLexer {
  private int $i = 0; private int $line = 1; private int $col = 1;
  public function __construct(private string $s) {}
  public function next(): array {
    $this->skip();
    if ($this->i >= strlen($this->s)) return ['type' => 'eof', 'value' => null, 'line' => $this->line, 'col' => $this->col];
    $c = $this->s[$this->i]; $l = $this->line; $p = $this->col;
    if (ctype_alpha($c) || $c === '_') return $this->ident();
    if ($c === '-' || ctype_digit($c)) return $this->number();
    if ($c === '"') return $this->str();
    if ($c === "'") $this->err('single-quoted string usage', $l, $p);
    if ($c === '/' && ($this->s[$this->i + 1] ?? '') === '/') $this->err('unexpected character', $l, $p);
    if (str_contains('=.,[]', $c)) { $this->adv(); return ['type' => $c, 'value' => $c, 'line' => $l, 'col' => $p]; }
    $this->err('unexpected character', $l, $p);
  }
  private function skip(): void {
    while ($this->i < strlen($this->s)) {
      $c = $this->s[$this->i];
      if ($c === '#') { while ($this->i < strlen($this->s) && $this->s[$this->i] !== "\n") $this->adv(); continue; }
      if ($c === ' ' || $c === "\t" || $c === "\r" || $c === "\n") { $this->adv(); continue; }
      break;
    }
  }
  private function ident(): array {
    $l = $this->line; $p = $this->col; $v = '';
    while ($this->i < strlen($this->s) && preg_match('/[A-Za-z0-9_]/', $this->s[$this->i])) { $v .= $this->s[$this->i]; $this->adv(); }
    $t = match ($v) { 'do' => 'do', 'end' => 'end', 'true' => 'bool', 'false' => 'bool', default => 'id' };
    $val = $t === 'bool' ? $v === 'true' : $v;
    return ['type' => $t, 'value' => $val, 'line' => $l, 'col' => $p];
  }
  private function number(): array {
    $l = $this->line; $p = $this->col; $n = ''; $dot = false;
    if ($this->s[$this->i] === '-') { $n .= '-'; $this->adv(); }
    if (!ctype_digit($this->s[$this->i] ?? '')) $this->err('unexpected token', $l, $p);
    while ($this->i < strlen($this->s)) {
      $c = $this->s[$this->i];
      if (ctype_digit($c)) { $n .= $c; $this->adv(); continue; }
      if ($c === '.' && !$dot) { $dot = true; $n .= '.'; $this->adv(); if (!ctype_digit($this->s[$this->i] ?? '')) $this->err('unexpected token', $l, $p); continue; }
      break;
    }
    return ['type' => 'number', 'value' => $dot ? (float)$n : (int)$n, 'raw' => $n, 'line' => $l, 'col' => $p];
  }
  private function str(): array {
    $l = $this->line; $p = $this->col; $this->adv(); $v = '';
    while ($this->i < strlen($this->s)) {
      $c = $this->s[$this->i];
      if ($c === '"') { $this->adv(); return ['type' => 'string', 'value' => $v, 'line' => $l, 'col' => $p]; }
      if ($c === '\\') {
        $e = $this->s[$this->i + 1] ?? null;
        if ($e === null) $this->err('unterminated string', $l, $p);
        $m = ['"' => '"', '\\' => '\\', 'n' => "\n", 't' => "\t"];
        if (!isset($m[$e])) $this->err('invalid escape', $this->line, $this->col);
        $v .= $m[$e]; $this->adv(); $this->adv(); continue;
      }
      if ($c === "\n") $this->err('unterminated string', $l, $p);
      $v .= $c; $this->adv();
    }
    $this->err('unterminated string', $l, $p);
  }
  private function adv(): void { if ($this->s[$this->i++] === "\n") { $this->line++; $this->col = 1; } else $this->col++; }
  private function err(string $m, int $l, int $c): never { throw new RCLParseError("line $l, column $c: $m"); }
}

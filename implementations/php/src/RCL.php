<?php
final class RCL {
  private static function run(string $op, string $text): string {
    $bridge = __DIR__ . '/../../ruby/lib/rcl/bridge.rb';
    $cmd = 'ruby ' . escapeshellarg($bridge) . ' ' . escapeshellarg($op);
    $des = [0 => ['pipe', 'r'], 1 => ['pipe', 'w'], 2 => ['pipe', 'w']];
    $p = proc_open($cmd, $des, $pipes, __DIR__ . '/..');
    if (!is_resource($p)) throw new RuntimeException('proc_open failed');
    fwrite($pipes[0], $text); fclose($pipes[0]);
    $out = stream_get_contents($pipes[1]); fclose($pipes[1]);
    $err = stream_get_contents($pipes[2]); fclose($pipes[2]);
    $code = proc_close($p);
    if ($code !== 0) throw new RuntimeException(trim($err));
    return $out;
  }
  public static function parse(string $text): array { return json_decode(self::run('parse', $text), true); }
  public static function format(string $text): string { return self::run('format', $text); }
  public static function toObject(string $text): array { return json_decode(self::run('object', $text), true); }
  public static function toYAML(string $text): string { return self::run('yaml', $text); }
  public static function toTOML(string $text): string { return self::run('toml', $text); }
  public static function toHCL(string $text): string { return self::run('hcl', $text); }
}

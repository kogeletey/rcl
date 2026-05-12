<?php
require __DIR__ . '/../src/RCL.php';
require __DIR__ . '/../src/RCLCore.php';

function ok(bool $v, string $m): void { if (!$v) { fwrite(STDERR, "$m\n"); exit(1); } }
function fails(string $src, string $needle): void {
  $hit = false;
  try { RCL::parse($src); } catch (Throwable $e) { $hit = str_contains($e->getMessage(), $needle) && str_contains($e->getMessage(), 'line'); }
  ok($hit, "expected failure: $needle");
}

$src = "root do\n  widget \"blue\" do\n    title = \"My Name\"\n    enabled = true\n    nums = [1, -2, 3.5]\n  end\nend\n";
$coreAst = RCLCore::parse($src);
ok($coreAst['type'] === 'Document', 'core ast type');
$coreObj = RCLCore::toObject($src);
ok($coreObj['root']['widgets']['blue']['title'] === 'My Name', 'core projection');
ok(!method_exists(RCLCore::class, 'format'), 'core has no formatter');
ok(!method_exists(RCLCore::class, 'toYAML'), 'core has no text converters');

$ast = RCL::parse($src);
ok($ast['type'] === 'Document', 'ast type');
ok(RCL::format($src) === $src, 'format canonical');
$obj = RCL::toObject($src);
ok($obj['root']['widgets']['blue']['title'] === 'My Name', 'generic named block');
ok($obj['root']['widgets']['blue']['enabled'] === true, 'bool projection');
ok(RCL::toTOML($src) !== '', 'toml output');
ok(RCL::toYAML($src) !== '', 'yaml output');
ok(RCL::toHCL($src) !== '', 'hcl output');

$src2 = "env \"prod\" do\n  region \"us\" do\n    a.b = 1\n  end\nend\n";
$o2 = RCL::toObject($src2);
ok($o2['envs']['prod']['regions']['us']['a']['b'] === 1, 'root named block');

fails("x do\n  name = value\nend\n", 'invalid bare identifier value');
fails("x do\n  arr = [1,]\nend\n", 'trailing comma in array');
fails("x do\n  a = 1\n  a = 2\nend\n", 'duplicate or conflicting key path');
fails("x do\n  a = 1\n  a.b = 2\nend\n", 'duplicate or conflicting key path');
fails("x do\n  a.b = 1\n  a = 2\nend\n", 'duplicate or conflicting key path');
fails("x do\n  s = \"bad\\q\"\nend\n", 'invalid escape');
fails("x do\n  s = \"ok\"\n", 'missing end');
fails("x do\n  a = [1,2\nend\n", 'missing ]');
fails("x do\n  s = \"bad\nend\n", 'unterminated string');
fails("x do\n  s = 'bad'\nend\n", 'single-quoted string usage');
fails("x do\n  @ = 1\nend\n", 'unexpected character');
fails("do [1] end\n", 'unexpected token after root array');
fails("x do\n  arr do [1]\n  y = 1\nend\n", 'unexpected token');

$namedArraySrc = "config do\n  tests do [\n    do\n      name = \"case-1\"\n    end,\n    \"string\"\n  ] end\nend\n";
$namedObj = RCL::toObject($namedArraySrc);
ok($namedObj['config']['tests'][0]['name'] === 'case-1', 'named array anonymous block item');
ok($namedObj['config']['tests'][1] === 'string', 'named array scalar item');

$rootArraySrc = "do [\n  do\n    name = \"root-item\"\n  end,\n  \"x\"\n]\n";
$rootObj = RCL::toObject($rootArraySrc);
ok($rootObj['root'][0]['name'] === 'root-item', 'root array anonymous block item');
ok($rootObj['root'][1] === 'x', 'root array scalar item');

echo "ok\n";

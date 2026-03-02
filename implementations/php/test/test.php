<?php
require __DIR__ . '/../src/RCL.php';
$src = "config do\n  region \"us\" do\n    name = \"My Name\"\n  end\nend\n";
$o = RCL::toObject($src);
if ($o['config']['regions']['us']['name'] !== 'My Name') { fwrite(STDERR, "projection failed\n"); exit(1); }
if (strpos(RCL::toTOML($src), '[config.regions.us]') === false) { fwrite(STDERR, "toml failed\n"); exit(1); }
$bad = "x do\n  name = value\nend\n";
$ok = false; try { RCL::parse($bad); } catch (Throwable $e) { $ok = true; }
if (!$ok) { fwrite(STDERR, "edge failed\n"); exit(1); }
echo "ok\n";

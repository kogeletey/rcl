import assert from "node:assert/strict";
import test from "node:test";
import { format, parse, parseSafe, toHCL, toObject, toTOML, toYAML } from "../src/index.js";

test("full spec parse + format", () => {
  const src = [
    "# comment",
    "server do",
    "  host = \"localhost\"",
    "  port = 8080",
    "  ratio = 3.14",
    "  negative = -42",
    "  enabled = true",
    "  names = [\"a\", \"b\", 1, false]",
    "  tls.cert_path = \"/etc/cert.pem\"",
    "  region \"us-east\" do",
    "    replicas = 2",
    "  end",
    "end",
  ].join("\n");

  const ast = parse(src);
  assert.equal(ast.kind, "document");
  assert.equal(ast.blocks[0]?.name, "server");
  assert.equal((ast.blocks[0]?.properties["enabled"] as any).value, true);
  assert.equal((ast.blocks[0]?.properties["negative"] as any).value, -42);
  assert.equal(((toObject(ast).tls as any).cert_path as any), "/etc/cert.pem");

  const out = format(ast);
  const reparsed = parse(out);
  assert.deepEqual(reparsed, ast);
});

test("named block maps to region.us object and converts", () => {
  const src = [
    "config do",
    "  region \"us\" do",
    "    name = \"My name\"",
    "  end",
    "end",
  ].join("\n");
  const ast = parse(src);
  const obj = toObject(ast);
  assert.equal((obj.region as any).us.name, "My name");
  assert.match(toYAML(ast), /region:/);
  assert.match(toTOML(ast), /\[region.us\]/);
  assert.match(toHCL(ast), /region \{/);
});

test("syntax error includes position", () => {
  const bad = "server do\n  a = [1, 2\nend";
  const res = parseSafe(bad);
  assert.equal(res.ok, false);
  if (!res.ok) {
    assert.ok(res.error.line > 0);
    assert.ok(res.error.column > 0);
  }
});

test("strict key/value edges", () => {
  const bad = [
    "x do\n  name = value\nend",
    "x do\n  arr = [1,]\nend",
    "x do\n  a = 1\n  a = 2\nend",
    "x do\n  a = 1\n  a.b = 2\nend",
  ];
  for (const src of bad) {
    const res = parseSafe(src);
    assert.equal(res.ok, false);
  }
});

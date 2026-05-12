import assert from "node:assert/strict";
import test from "node:test";
import * as core from "../src/core.js";
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
  assert.equal((((toObject(ast).server as any).tls as any).cert_path as any), "/etc/cert.pem");

  const out = format(ast);
  const reparsed = parse(out);
  assert.deepEqual(reparsed, ast);
});

test("named block maps to config.regions.us object and converts", () => {
  const src = [
    "config do",
    "  region \"us\" do",
    "    name = \"My name\"",
    "  end",
    "end",
  ].join("\n");
  const ast = parse(src);
  const obj = toObject(ast);
  assert.equal((obj.config as any).regions.us.name, "My name");
  assert.match(toYAML(ast), /regions:/);
  assert.match(toTOML(ast), /\[config.regions.us\]/);
  assert.match(toHCL(ast), /regions \{/);
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

test("supports named/root arrays and anonymous block array elements", () => {
  const named = [
    "config do",
    "  tests do [",
    "    do",
    "      name = \"case-1\"",
    "    end,",
    "    \"string\"",
    "  ] end",
    "end",
  ].join("\n");
  const namedAst = parse(named);
  const namedObj = toObject(namedAst);
  assert.equal((((namedObj.config as any).tests as any[])[0] as any).name, "case-1");
  assert.equal((((namedObj.config as any).tests as any[])[1] as any), "string");
  assert.match(format(namedAst), /tests do \[/);

  const root = [
    "do [",
    "  do",
    "    name = \"root-item\"",
    "  end,",
    "  \"x\"",
    "]",
  ].join("\n");
  const rootAst = parse(root);
  const rootObj = toObject(rootAst);
  assert.equal(((rootObj.root as any[])[0] as any).name, "root-item");
  assert.equal((rootObj.root as any[])[1], "x");
});

test("core entrypoint exposes parse + toObject but not formatter/converters", () => {
  const src = "config do\n  region \"us\" do\n    name = \"My name\"\n  end\nend";
  const ast = core.parse(src);
  const obj = core.toObject(ast);
  assert.equal((obj.config as any).regions.us.name, "My name");
  assert.equal("format" in core, false);
  assert.equal("toYAML" in core, false);
  assert.equal("toTOML" in core, false);
  assert.equal("toHCL" in core, false);
});

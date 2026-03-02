import assert from "node:assert/strict";
import test from "node:test";
import { parse, format } from "../src/index.js";

test("parse and format simple block", () => {
  const source = 'xray do\n  port = 8080\n  enabled = true\nend';
  const ast = parse(source);

  assert.equal(ast.kind, "document");
  assert.equal(ast.blocks[0]?.name, "xray");

  const out = format(ast);
  assert.equal(out, source);
});

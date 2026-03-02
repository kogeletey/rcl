import { AstNode, BlockNode, DocumentNode } from "./ast.js";

type V = string | number | boolean | V[] | { [k: string]: V };

function nodeToValue(node: AstNode): V {
  if (node.kind === "string") return node.value;
  if (node.kind === "number") return node.value;
  if (node.kind === "boolean") return node.value;
  if (node.kind === "array") return node.elements.map(nodeToValue);
  throw new Error(`unsupported node kind ${node.kind}`);
}

function uniqChildren(block: BlockNode): BlockNode[] {
  const seen = new Set<BlockNode>();
  const out: BlockNode[] = [];
  for (const child of Object.values(block.blocks)) {
    if (seen.has(child)) continue;
    seen.add(child);
    out.push(child);
  }
  for (const child of block.named_blocks ?? []) {
    if (seen.has(child)) continue;
    seen.add(child);
    out.push(child);
  }
  return out;
}

function blockToObject(block: BlockNode): { [k: string]: V } {
  const result: { [k: string]: V } = {};
  for (const [k, v] of Object.entries(block.properties)) insertPath(result, k, nodeToValue(v));

  const children = uniqChildren(block);
  for (const child of children.filter((c) => c.argument === undefined)) {
    const existing = result[child.name];
    const childObj = blockToObject(child);
    if (existing && typeof existing === "object" && !Array.isArray(existing)) {
      result[child.name] = { ...childObj, ...(existing as { [k: string]: V }) };
    } else result[child.name] = childObj;
  }

  for (const child of children.filter((c) => c.argument !== undefined)) {
    const base = namedBase(child.name);
    const arg = child.argument as string;
    const branch = result[base];
    const parent = branch && typeof branch === "object" && !Array.isArray(branch) ? (branch as { [k: string]: V }) : {};
    parent[arg] = blockToObject(child);
    result[base] = parent;
  }
  return result;
}

function insertPath(target: { [k: string]: V }, key: string, value: V): void {
  const parts = key.split(".");
  if (parts.length === 1) {
    if (Object.prototype.hasOwnProperty.call(target, key)) throw new Error(`duplicate key '${key}'`);
    target[key] = value;
    return;
  }
  const head = parts[0]!;
  const current = target[head];
  if (current !== undefined && (typeof current !== "object" || Array.isArray(current))) throw new Error(`key conflict at '${head}'`);
  const branch = (current as { [k: string]: V } | undefined) ?? {};
  insertPath(branch, parts.slice(1).join("."), value);
  target[head] = branch;
}

export function toObject(document: DocumentNode): { [k: string]: V } {
  const out: { [k: string]: V } = {};
  for (const block of document.blocks) {
    if (block.argument !== undefined) out[namedBase(block.name)] = { [block.argument]: blockToObject(block) };
    else out[block.name] = blockToObject(block);
  }
  return out;
}

function namedBase(name: string): string { return name === "region" ? "regions" : name; }

function esc(s: string): string {
  return s.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, "\\n").replace(/\t/g, "\\t");
}

function emitYAML(v: V, indent = 0): string {
  const pad = "  ".repeat(indent);
  if (Array.isArray(v)) {
    return v.map((item) => (typeof item === "object" ? `${pad}-\n${emitYAML(item as V, indent + 1)}` : `${pad}- ${emitScalar(item)}`)).join("\n");
  }
  if (typeof v === "object") {
    return Object.keys(v).sort().map((k) => {
      const item = (v as { [k: string]: V })[k];
      if (typeof item === "object") return `${pad}${k}:\n${emitYAML(item as V, indent + 1)}`;
      return `${pad}${k}: ${emitScalar(item)}`;
    }).join("\n");
  }
  return `${pad}${emitScalar(v)}`;
}

function emitTOML(v: { [k: string]: V }): string {
  const out: string[] = [];
  const walk = (obj: { [k: string]: V }, prefix?: string): void => {
    for (const k of Object.keys(obj).sort()) {
      const item = obj[k];
      if (typeof item === "object" && !Array.isArray(item)) continue;
      out.push(`${k} = ${emitScalar(item as V)}`);
    }
    for (const k of Object.keys(obj).sort()) {
      const item = obj[k];
      if (!(typeof item === "object") || Array.isArray(item)) continue;
      const sec = prefix ? `${prefix}.${k}` : k;
      if (out.length > 0) out.push("");
      out.push(`[${sec}]`);
      walk(item as { [k: string]: V }, sec);
    }
  };
  walk(v);
  return out.join("\n");
}

function emitHCL(v: V, indent = 0): string {
  const pad = "  ".repeat(indent);
  if (typeof v !== "object" || Array.isArray(v)) return `${pad}${emitScalar(v as V)}`;
  const lines: string[] = [];
  for (const k of Object.keys(v).sort()) {
    const item = (v as { [k: string]: V })[k];
    if (typeof item === "object" && !Array.isArray(item)) {
      lines.push(`${pad}${k} {`);
      lines.push(emitHCL(item, indent + 1));
      lines.push(`${pad}}`);
    } else lines.push(`${pad}${k} = ${emitScalar(item)}`);
  }
  return lines.join("\n");
}

function emitScalar(v: V): string {
  if (typeof v === "string") return `"${esc(v)}"`;
  if (typeof v === "number") return `${v}`;
  if (typeof v === "boolean") return v ? "true" : "false";
  if (Array.isArray(v)) return `[${v.map(emitScalar).join(", ")}]`;
  return "{}";
}

export function toYAML(document: DocumentNode): string { return emitYAML(toObject(document)); }
export function toTOML(document: DocumentNode): string { return emitTOML(toObject(document)); }
export function toHCL(document: DocumentNode): string { return emitHCL(toObject(document)); }

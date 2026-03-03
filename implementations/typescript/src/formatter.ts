import { AstNode, BlockNode, DocumentNode } from "./ast.js";

function q(s: string): string {
  return `"${s.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, "\\n").replace(/\t/g, "\\t")}"`;
}

function formatValue(node: AstNode): string {
  if (node.kind === "string") return q(node.value);
  if (node.kind === "number") return `${node.value}`;
  if (node.kind === "boolean") return node.value ? "true" : "false";
  if (node.kind === "array") return `[${node.elements.map(formatValue).join(", ")}]`;
  if (node.kind === "block") return formatAnonymousBlock(node);
  throw new Error(`unsupported value kind: ${node.kind}`);
}

function formatBlock(block: BlockNode, indent = 0): string {
  const pad = "  ".repeat(indent);
  const head = block.argument ? `${pad}${block.name} ${q(block.argument)} do` : `${pad}${block.name} do`;
  const out: string[] = [head];

  for (const [k, v] of Object.entries(block.properties)) {
    if (v.kind === "array") out.push(`${pad}  ${k} do ${formatValue(v)} end`);
    else out.push(`${pad}  ${k} = ${formatValue(v)}`);
  }

  const seen = new Set<BlockNode>();
  for (const child of Object.values(block.blocks)) {
    if (seen.has(child)) continue;
    seen.add(child);
    out.push(formatBlock(child, indent + 1));
  }
  for (const child of block.named_blocks ?? []) {
    if (seen.has(child)) continue;
    seen.add(child);
    out.push(formatBlock(child, indent + 1));
  }

  out.push(`${pad}end`);
  return out.join("\n");
}

export function format(document: DocumentNode): string {
  if (document.root_value && document.root_value.kind === "array") {
    return `do ${formatValue(document.root_value)}`;
  }
  return document.blocks.map((b) => formatBlock(b)).join("\n\n");
}

function formatAnonymousBlock(block: BlockNode): string {
  const parts: string[] = [];
  for (const [k, v] of Object.entries(block.properties)) parts.push(`${k} = ${formatValue(v)}`);
  for (const child of Object.values(block.blocks)) parts.push(formatInlineBlock(child));
  for (const child of block.named_blocks ?? []) parts.push(formatInlineBlock(child));
  return parts.length === 0 ? "do end" : `do ${parts.join(" ")} end`;
}

function formatInlineBlock(block: BlockNode): string {
  const head = block.argument ? `${block.name} ${q(block.argument)} do` : `${block.name} do`;
  const parts: string[] = [];
  for (const [k, v] of Object.entries(block.properties)) parts.push(`${k} = ${formatValue(v)}`);
  for (const child of Object.values(block.blocks)) parts.push(formatInlineBlock(child));
  for (const child of block.named_blocks ?? []) parts.push(formatInlineBlock(child));
  return parts.length === 0 ? `${head} end` : `${head} ${parts.join(" ")} end`;
}

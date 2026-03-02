import { AstNode, BlockNode, DocumentNode } from "./ast.js";

function q(s: string): string {
  return `"${s.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, "\\n").replace(/\t/g, "\\t")}"`;
}

function formatValue(node: AstNode): string {
  if (node.kind === "string") return q(node.value);
  if (node.kind === "number") return `${node.value}`;
  if (node.kind === "boolean") return node.value ? "true" : "false";
  if (node.kind === "array") return `[${node.elements.map(formatValue).join(", ")}]`;
  throw new Error(`unsupported value kind: ${node.kind}`);
}

function formatBlock(block: BlockNode, indent = 0): string {
  const pad = "  ".repeat(indent);
  const head = block.argument ? `${pad}${block.name} ${q(block.argument)} do` : `${pad}${block.name} do`;
  const out: string[] = [head];

  for (const [k, v] of Object.entries(block.properties)) out.push(`${pad}  ${k} = ${formatValue(v)}`);

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
  return document.blocks.map((b) => formatBlock(b)).join("\n\n");
}

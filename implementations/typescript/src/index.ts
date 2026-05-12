import { DocumentNode, ParseError } from "./ast.js";
import { ParserException } from "./error.js";
import { format } from "./formatter.js";
import { parse } from "./core.js";
import { toHCL, toObject, toTOML, toYAML } from "./convert.js";

export * from "./ast.js";

export function parseSafe(text: string): { ok: true; ast: DocumentNode } | { ok: false; error: ParseError } {
  try {
    return { ok: true, ast: parse(text) };
  } catch (err) {
    if (err instanceof ParserException) {
      return { ok: false, error: { message: err.message, line: err.line, column: err.column } };
    }
    return { ok: false, error: { message: String(err), line: 0, column: 0 } };
  }
}

export { format };
export { toObject, toYAML, toTOML, toHCL };

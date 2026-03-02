# @rcl/parser

> Under Construction, need help with this

TypeScript parser/formatter/converter package for RCL.

## Install

```bash
npm install @rcl/parser
```

## Usage

```ts
import { parse, format, toYAML, toTOML, toHCL, toObject } from "@rcl/parser";

const ast = parse('config do\n  region "us" do\n    name = "My Name"\n  end\nend');
const obj = toObject(ast); // { config: { regions: { us: { name: "My Name" } } } }
const yaml = toYAML(ast);
const toml = toTOML(ast);
const hcl = toHCL(ast);
const rcl = format(ast);
```

Constraints: `#` comments only, strings in double quotes only, dotted keys are nested, duplicate/conflicting keys fail.

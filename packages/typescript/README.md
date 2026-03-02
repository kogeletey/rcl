# @rcl/parser

> Under Construction, need help with this

TypeScript parser/formatter package for RCL.

## Install

```bash
npm install @rcl/parser
```

## Usage

```ts
import { parse, format } from "@rcl/parser";

const ast = parse('xray do\n  port = 8080\nend');
console.log(ast.kind);
console.log(format(ast));
```

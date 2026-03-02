# rcl-php

Native PHP implementation of RCL v1 with lexer, parser, AST, formatter, projection, and YAML/TOML/HCL converters.

## API

- `RCL::parse(string): array` returns AST document with block/property/value nodes
- `RCL::format(string): string` canonical `do ... end` formatting
- `RCL::toObject(string): array` projected object
- `RCL::toYAML(string): string`
- `RCL::toTOML(string): string`
- `RCL::toHCL(string): string`

## Guarantees

- Generic named block projection (`name "x"` -> `names.x`)
- Dotted key insertion
- Duplicate and prefix key-path conflict detection
- Strict string and array syntax validation
- Parse errors include `line` and `column`

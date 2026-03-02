# rcl-dart

Native Dart implementation of RCL v1 with lexer, parser, AST, formatter, projection, and YAML/TOML/HCL converters.

## API

- `RCL.parse(String)` returns AST document with block/property/value nodes
- `RCL.format(String)` canonical `do ... end` formatting
- `RCL.toObject(String)` projected object
- `RCL.toYAML(String)`
- `RCL.toTOML(String)`
- `RCL.toHCL(String)`

## Guarantees

- Generic named block projection (`name "x"` -> `names.x`)
- Dotted key insertion
- Duplicate and prefix key-path conflict detection
- Strict string and array syntax validation
- Parse errors include `line` and `column`

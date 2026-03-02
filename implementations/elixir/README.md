# rcl-elixir

Native Elixir implementation of RCL v1 with lexer, parser, AST, formatter, projection, and YAML/TOML/HCL converters.

## API

- `RCL.parse/1` returns AST document with block/property/value nodes
- `RCL.format/1` canonical `do ... end` formatting
- `RCL.to_object/1` projected object
- `RCL.to_yaml/1`
- `RCL.to_toml/1`
- `RCL.to_hcl/1`

## Guarantees

- Generic named block projection (`name "x"` -> `names.x`)
- Dotted key insertion
- Duplicate and prefix key-path conflict detection
- Strict string and array syntax validation
- Parse errors include `line` and `column`

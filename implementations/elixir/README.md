# rcl-elixir

Native Elixir implementation of RCL v1 with lexer, parser, AST, formatter, projection, and YAML/TOML/HCL converters.

## API

Core entrypoint (`RCLCore`) includes only parse + object projection.

```elixir
ast = RCLCore.parse("xray do\n  port = 8080\nend\n")
obj = RCLCore.to_object("xray do\n  port = 8080\nend\n")
```

- `RCLCore.parse/1` returns AST document with block/property/value nodes
- `RCLCore.to_object/1` projected object

Extended entrypoint (`RCL`) preserves the existing full API.

```elixir
formatted = RCL.format("xray do\n  port = 8080\nend\n")
yaml = RCL.to_yaml("xray do\n  port = 8080\nend\n")
```

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

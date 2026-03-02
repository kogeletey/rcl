# rcl-rust

> Under Construction, need help with this

Rust parser/formatter/converter package for full RCL spec.

## Usage

```rust
let doc = rcl_parser::parse(source)?;
let obj = rcl_parser::to_object(&doc);
let yaml = rcl_parser::to_yaml(&doc);
let toml = rcl_parser::to_toml(&doc);
let hcl = rcl_parser::to_hcl(&doc);
let out = rcl_parser::format(&doc);
```

Constraints: `#` comments only, strings in double quotes only, dotted keys are nested, duplicate/conflicting keys fail.

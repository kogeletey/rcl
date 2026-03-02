# rcl-swift

> Under Construction, need help with this

Swift parser/formatter/converter for full RCL spec.

## Usage

```swift
let ast = try RCL.parse(source)
let obj = Converters.toObject(ast)
let yaml = Converters.toYAML(ast)
let toml = Converters.toTOML(ast)
let hcl = Converters.toHCL(ast)
let out = Formatter.format(ast)
```

Constraints: `#` comments only, strings in double quotes only, dotted keys are nested, duplicate/conflicting keys fail.

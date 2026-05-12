# rcl-swift

> Under Construction, need help with this

Swift parser/formatter/converter for full RCL spec.

## Core API (`RCLCore`)

```swift
let ast = try RCLCore.parse(source)
let obj = RCLCore.toObject(ast)
```

## Extended API (`RCL`)

```swift
let ast = try RCL.parse(source)
let out = RCL.format(ast)
let yaml = RCL.toYAML(ast)
let toml = RCL.toTOML(ast)
let hcl = RCL.toHCL(ast)
```

Constraints: `#` comments only, strings in double quotes only, dotted keys are nested, duplicate/conflicting keys fail.

# rcl-swift

> Under Construction, need help with this

Swift parser/formatter for full RCL spec.

## Features

- Full lexer/parser support for spec types and block syntax
- `#` comments
- Formatter with roundtrip compatibility
- Position-aware parse errors

## Usage

```swift
let ast = try RCL.parse(source)
let out = Formatter.format(ast)
```

## Test

```bash
swift test
```

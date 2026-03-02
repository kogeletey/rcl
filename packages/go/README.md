# rcl-go

> Under Construction, need help with this

Go parser/formatter for full RCL spec.

## Features

- Full lexer/parser support: blocks, nested blocks, dotted keys, strings, numbers, booleans, arrays
- `#` comments
- Canonical formatter with parse->format->parse stability
- Position-aware parse errors

## Usage

```go
doc, err := rcl.Parse(source)
out, err := rcl.Format(doc)
```

## Test

```bash
go test ./...
```

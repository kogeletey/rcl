# rcl-go

> Under Construction, need help with this

Go parser/formatter/converter for full RCL spec.

## Usage

```go
doc, err := rcl.Parse(source)
obj := rcl.ToObject(doc)
yaml, _ := rcl.ToYAML(doc)
toml, _ := rcl.ToTOML(doc)
hcl, _ := rcl.ToHCL(doc)
out, _ := rcl.Format(doc)
```

## Test

```bash
go test ./...
```

Constraints: `#` comments only, strings in double quotes only, dotted keys are nested, duplicate/conflicting keys fail.

# rcl-csharp

Native C# implementation of RCL v1.

## API

- `RCL.Parse(string)` -> `DocumentNode`
- `RCL.Format(string|DocumentNode)`
- `RCL.ToObject(string|DocumentNode)`
- `RCL.ToYAML(string|DocumentNode)`
- `RCL.ToTOML(string|DocumentNode)`
- `RCL.ToHCL(string|DocumentNode)`

Parser validates full spec with line/column errors and generic named-block projection (`name` -> `names`).

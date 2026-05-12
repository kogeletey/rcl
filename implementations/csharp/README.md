# rcl-csharp

Native C# implementation of RCL v1.

## Core API (`RCLImpl.Core.RCL`)

- `Parse(string)` -> `DocumentNode`
- `ToObject(string|DocumentNode)`

```csharp
var ast = RCLImpl.Core.RCL.Parse(source);
var obj = RCLImpl.Core.RCL.ToObject(ast);
```

## Extended API (`RCLImpl.RCL`)

- `RCL.Parse(string)` -> `DocumentNode`
- `RCL.Format(string|DocumentNode)`
- `RCL.ToObject(string|DocumentNode)`
- `RCL.ToYAML(string|DocumentNode)`
- `RCL.ToTOML(string|DocumentNode)`
- `RCL.ToHCL(string|DocumentNode)`

```csharp
var ast = RCLImpl.RCL.Parse(source);
var formatted = RCLImpl.RCL.Format(ast);
var yaml = RCLImpl.RCL.ToYAML(ast);
```

Parser validates full spec with line/column errors and generic named-block projection (`name` -> `names`).

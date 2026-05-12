# rcl-java

Native Java implementation of RCL v1.

## Core API (`io.rcl.core.RCL`)

- `parse(String)` -> `DocumentNode`
- `toObject(String|DocumentNode)`

```java
DocumentNode ast = io.rcl.core.RCL.parse(source);
Map<String, Object> obj = io.rcl.core.RCL.toObject(ast);
```

## Extended API (`io.rcl.RCL`)

- `RCL.parse(String)` -> `DocumentNode`
- `RCL.format(String|DocumentNode)`
- `RCL.toObject(String|DocumentNode)`
- `RCL.toYAML(String|DocumentNode)`
- `RCL.toTOML(String|DocumentNode)`
- `RCL.toHCL(String|DocumentNode)`

```java
DocumentNode ast = RCL.parse(source);
String formatted = RCL.format(ast);
String yaml = RCL.toYAML(ast);
```

Parser validates full spec including dotted keys, named blocks, key conflicts, escapes and line/column errors.

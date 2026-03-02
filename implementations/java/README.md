# rcl-java

Native Java implementation of RCL v1.

## API

- `RCL.parse(String)` -> `DocumentNode`
- `RCL.format(String|DocumentNode)`
- `RCL.toObject(String|DocumentNode)`
- `RCL.toYAML(String|DocumentNode)`
- `RCL.toTOML(String|DocumentNode)`
- `RCL.toHCL(String|DocumentNode)`

Parser validates full spec including dotted keys, named blocks, key conflicts, escapes and line/column errors.

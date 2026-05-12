# rcl-dart

Native Dart implementation of RCL v1 with lexer, parser, AST, formatter, projection, and YAML/TOML/HCL converters.

## API

Core entrypoint (`package:rcl/rcl_core.dart`) includes only parse + object projection.

```dart
import 'package:rcl/rcl_core.dart';

final ast = RCLCore.parse('xray do\n  port = 8080\nend\n');
final obj = RCLCore.toObject('xray do\n  port = 8080\nend\n');
```

- `RCLCore.parse(String)` returns AST document with block/property/value nodes
- `RCLCore.toObject(String)` projected object

Extended entrypoint (`package:rcl/rcl.dart`) preserves the existing full API.

```dart
import 'package:rcl/rcl.dart';

final formatted = RCL.format('xray do\n  port = 8080\nend\n');
final yaml = RCL.toYAML('xray do\n  port = 8080\nend\n');
```

- `RCL.parse(String)` returns AST document with block/property/value nodes
- `RCL.format(String)` canonical `do ... end` formatting
- `RCL.toObject(String)` projected object
- `RCL.toYAML(String)`
- `RCL.toTOML(String)`
- `RCL.toHCL(String)`

## Guarantees

- Generic named block projection (`name "x"` -> `names.x`)
- Dotted key insertion
- Duplicate and prefix key-path conflict detection
- Strict string and array syntax validation
- Parse errors include `line` and `column`

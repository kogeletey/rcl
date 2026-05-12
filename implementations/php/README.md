# rcl-php

Native PHP implementation of RCL v1 with lexer, parser, AST, formatter, projection, and YAML/TOML/HCL converters.

## API

Core entrypoint (`RCLCore`) includes only parse + object projection.

```php
<?php
require 'vendor/autoload.php';

$ast = RCLCore::parse("xray do\n  port = 8080\nend\n");
$obj = RCLCore::toObject("xray do\n  port = 8080\nend\n");
```

- `RCLCore::parse(string): array` returns AST document with block/property/value nodes
- `RCLCore::toObject(string): array` projected object

Extended entrypoint (`RCL`) preserves the existing full API.

```php
<?php
require 'vendor/autoload.php';

$formatted = RCL::format("xray do\n  port = 8080\nend\n");
$yaml = RCL::toYAML("xray do\n  port = 8080\nend\n");
```

- `RCL::parse(string): array` returns AST document with block/property/value nodes
- `RCL::format(string): string` canonical `do ... end` formatting
- `RCL::toObject(string): array` projected object
- `RCL::toYAML(string): string`
- `RCL::toTOML(string): string`
- `RCL::toHCL(string): string`

## Guarantees

- Generic named block projection (`name "x"` -> `names.x`)
- Dotted key insertion
- Duplicate and prefix key-path conflict detection
- Strict string and array syntax validation
- Parse errors include `line` and `column`

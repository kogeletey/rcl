# RCL - Ruby-like Configuration Language

A Ruby-like configuration language parser written in Crystal.

## Features

- Ruby-like syntax - Simple, readable configuration format
- Standalone parser - Independent library, reusable for any project
- Custom block handlers - Register handlers for specific block types
- Type-safe values - Strings, numbers, booleans, arrays, nested blocks
- Comments - Support for # comments
- Stable AST contract - `Document#to_json`
- Formatter - Convert parsed AST back to canonical RCL text
- Native conversion - Export to YAML/TOML/HCL
- Named blocks - `region "us" do` projects to `regions.us`

## Installation

For local development, add dependency from monorepo path:

```yaml
dependencies:
  rcl:
    path: ./implementations/crystal
```

## Usage

```crystal
require "rcl"

# Parse a file
doc = RCL.parse_file("config.rcl")

# Parse a string
doc = RCL.parse_string("key = \"value\"")

# Access values
doc.get_string("server.address")
doc.get_int("server.port")
doc.get_bool("feature.enabled")

# Convert to Hash
hash = doc.to_h

# AST JSON
json = doc.to_json

# Format
source = RCL.format(doc)

# Convert
yaml = RCL.to_yaml(doc)
toml = RCL.to_toml(doc)
hcl = RCL.to_hcl(doc)
```

Named block projection example:

```rcl
config do
  region "us" do
    name = "My Name"
  end
end
```

```json
{ "config": { "regions": { "us": { "name": "My Name" } } } }
```

Constraints:

- Comments: `#` only
- Strings: double quotes only (`"..."`)
- Bare identifier values are invalid (`name = value` fails)
- Dotted keys are nested (`a.b = 1` -> `{a: {b: 1}}`)
- Duplicate/conflicting key paths fail

## Example RCL File

```rcl
# Server configuration
server do
  address = "example.com"
  port = 8080
  enabled = true
end

# List of features
features = ["auth", "logging", "cache"]
```

## Development

```bash
# Install dependencies
cd implementations/crystal && crystal deps

# Run tests
cd implementations/crystal && crystal spec

# Build
cd implementations/crystal && crystal build src/rcl.cr
```

## Implementations

Multi-language workspace is available under `implementations/`.

- `implementations/crystal` - Crystal parser + formatter + converters
- `implementations/ruby` - Ruby parser + formatter
- `implementations/typescript` - TypeScript parser + formatter
- `implementations/go` - Go parser + formatter + converters
- `implementations/kotlin` - Kotlin parser + formatter + converters
- `implementations/swift` - Swift parser + formatter + converters
- `implementations/rust` - Rust parser + formatter + converters
- `implementations/php` - PHP parser + formatter + converters
- `implementations/elixir` - Elixir parser + formatter + converters
- `implementations/ocaml` - OCaml parser + formatter + converters
- `implementations/julia` - Julia parser + formatter + converters
- `implementations/c` - C parser + formatter + converters
- `implementations/cpp` - C++ parser + formatter + converters
- `implementations/zig` - Zig parser + formatter + converters
- `implementations/java` - Java parser + formatter + converters
- `implementations/d` - D parser + formatter + converters
- `implementations/csharp` - C# parser + formatter + converters
- `implementations/lua` - Lua parser + formatter + converters
- `implementations/dart` - Dart parser + formatter + converters

## License

MIT

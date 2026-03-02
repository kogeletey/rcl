# RCL - Ruby-like Configuration Language

A Ruby-like configuration language parser written in Crystal.

## Features

- Ruby-like syntax - Simple, readable configuration format
- Standalone parser - Independent library, reusable for any project
- Custom block handlers - Register handlers for specific block types
- Type-safe values - Strings, numbers, booleans, arrays, nested blocks
- Comments - Support for # comments
- Stable AST contract - `Document#to_ast_h` and `Document#to_json`
- Formatter - Convert parsed AST back to canonical RCL text
- Native conversion - Export to YAML/TOML/HCL
- Named blocks - `region "us" do` projects to `regions.us`

## Installation

Add to your `shard.yml`:

```yaml
dependencies:
  rcl:
    github: yourusername/rcl
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
crystal deps

# Run tests
crystal spec

# Build
crystal build
```

## Packages

Multi-language package workspace is available under `packages/`.

- `packages/ruby` - Ruby parser + formatter
- `packages/typescript` - TypeScript parser + formatter
- `packages/go` - Go parser + formatter + converters
- `packages/kotlin` - Kotlin parser + formatter + converters
- `packages/swift` - Swift parser + formatter + converters
- `packages/rust` - Rust parser + formatter + converters

## License

MIT

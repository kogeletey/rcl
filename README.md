# RCL - Ruby-like Configuration Language

A Ruby-like configuration language parser written in Crystal. It's designed to describe application settings in a clean, readable format.

## Why to choose RCL instead of...

| Format | RCL Advantage |
|--------|---------------|
| YAML | No indentation sensitivity, Ruby-like syntax |
| JSON | Readable by humans, comments support |
| TOML | Better for nested structures |
| XML | Simple and clean |
| HCL | Simpler, Ruby-like syntax |
| .env | Structured data, nested blocks |
| Ruby files | **No code execution** - safe for config |

## Features
 
- Ruby-like syntax - Simple, readable configuration format
- Standalone parser - Independent library, reusable for any project
- Custom block handlers - Register handlers for specific block types
- Type-safe values - Strings, numbers, booleans, arrays, nested blocks
- Formatter - Convert parsed AST back to canonical RCL text
- Native conversion - Export to YAML/TOML/HCL
- **Easy to type on mobile devices** - minimal punctuation, clean syntax

## API Reference

| Method | Returns | Description |
|--------|---------|-------------|
| `parse_file(path)` | `Document` | Parse RCL file |
| `parse_string(str)` | `Document` | Parse RCL string |
| `format(doc)` | `String` | Convert AST back to RCL source |
| `get_string(path)` | `String?` | Get string (nil if not found) |
| `get_int(path)` | `Int32?` | Get integer (nil if not found) |
| `get_float(path)` | `Float64?` | Get float (nil if not found) |
| `get_bool(path)` | `Bool?` | Get boolean (nil if not found) |
| `get_array(path)` | `ArrayNode?` | Get array node (nil if not found) |
| `has_key?(path)` | `Bool` | Check if key exists |

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
if address = doc.get_string("server.address")
  connect_to_server(address) # example
end

port = doc.get_int("server.port", 8080)
start_server(port) # example

if enabled = doc.get_bool("feature.enabled")
  enable_feature() # example

if features = doc.get_array("features")
  features.elements.each do |f|
    puts "Feature: #{f}"
  end
end


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
app "myapp" do
  environment = "myapp"
  debug = false
  log_level = "warn"

  # Server configuration
  server do
    address = "example.com"
    port = 8080
    enabled = true
    ssl.cert_path = "/etc/ssl/cert.pem"

    # Resource limits
    limits do
      max_connections = 1000
      timeout = 30
    end
  end

  # Database configuration
  database "primary" do
    adapter = "postgresql"
    host = "db.internal"
    name = "myapp"
    pool = 20
  end
end

# List of features
features = ["auth", "logging", "cache"]
```

```json
{
  "apps": {
    "myapp": {
      "environment": "myapp",
      "debug": false,
      "log_level": "warn",
      "server": {
        "address": "example.com",
        "port": 8080,
        "enabled": true,
        "ssl": {
          "cert_path": "/etc/ssl/cert.pem"
        },
        "limits": {
          "max_connections": 1000,
          "timeout": 30
        }
      },
      "databases": {
        "primary": {
          "adapter": "postgresql",
          "host": "db.internal",
          "name": "myapp",
          "pool": 20
        }
      }
    }
  },
  "features": ["auth", "logging", "cache"]
}
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

# RCL - Ray Configuration Language

A TOML-like configuration language parser written in Crystal.

## Features

- 📝 **TOML-like syntax** - Simple, readable configuration format
- 🔧 **Standalone parser** - Independent library, reusable for any project
- 🧩 **Custom block handlers** - Register handlers for specific block types
- 📊 **Type-safe values** - Strings, numbers, booleans, arrays, nested blocks
- 💬 **Comments** - Support for `#` and `//` comments

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
doc.get_string("server/address")
doc.get_int("server/port")
doc.get_bool("feature/enabled")

# Convert to Hash
hash = doc.to_h
```

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

## License

MIT

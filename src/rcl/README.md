# RCL - Ruby-like Configuration Language

A Ruby-like configuration language parser written in Crystal.

## Features

- Ruby-like syntax - Simple, readable configuration format
- Standalone parser - Independent library, reusable for any project
- Custom block handlers - Register handlers for specific block types
- Type-safe values - Strings, numbers, booleans, arrays, nested blocks
- Comments - Support for # and // comments

## Installation

Add to your `shard.yml`:

```yaml
dependencies:
  rcl:
    github: yourusername/rcl
```

## Usage

### Basic Parsing

```crystal
require "rcl"

# Parse a file
doc = RCL.parse_file("config.rcl")

# Parse a string
doc = RCL.parse_string("key = \"value\"")

# Access values
doc["key"]      # => StringNode
doc.get("section/key")  # => nested value

# Get typed values
doc.get_string("server/address")    # => String?
doc.get_int("server/port")          # => Int32?
doc.get_float("settings/ratio")     # => Float64?
doc.get_bool("feature/enabled")     # => Bool?

# Convert to Hash
hash = doc.to_h
```

### Example RCL File

```rcl
# Server configuration
server do
  address = "example.com"
  port = 8080
  enabled = true
end

# Database settings
database do
  host = "localhost"
  port = 5432
  name = "myapp"

  pool do
    size = 10
    timeout = 30.5
  end
end

# List of features
features = ["auth", "logging", "cache"]
```

### Custom Block Handlers

Register handlers for specific block types:

```crystal
require "rcl"

# Register handler for "server" blocks
RCL::Blocks.register("server") do |block|
  config = ServerConfig.new
  config.address = block["address"].as(StringNode).value
  config.port = block["port"].as(NumberNode).value.to_i
  {:ok, {config: config}.named_tuple}
end

# Register handler for "database" blocks
RCL::Blocks.register("database") do |block|
  db_config = DBConfig.new
  db_config.host = block["host"].as(StringNode).value
  db_config.port = block["port"].as(NumberNode).value.to_i
  {:ok, {db: db_config}.named_tuple}
end

# Process document with handlers
doc = RCL.parse_file("config.rcl")
results = RCL::Blocks.process_document(doc)

results.each do |result|
  if result[:status] == :ok
    puts "Processed: #{result[:data]}"
  else
    puts "Unknown block: #{result[:data][:block].name}"
  end
end
```

## Syntax

### Values

```rcl
# Strings (double quotes required)
name = "John Doe"
path = "/usr/local/bin"

# Numbers (integers and floats)
port = 8080
ratio = 3.14
large = 12598959

# Booleans
enabled = true
disabled = false

# Arrays
items = ["apple", "banana", "cherry"]
numbers = [1, 2, 3, 4, 5]

# Nested blocks
server do
  host = "localhost"
  port = 3000

  ssl do
    enabled = true
    cert = "/path/to/cert"
  end
end
```

### Comments

```rcl
# Ruby-style hash comments
key = "value" # Inline comment

block do
  value = 123  # Inline comment
end
```

## API Reference

### RCL Module

| Method | Description |
|--------|-------------|
| `parse_file(path)` | Parse RCL file, return Document |
| `parse_string(content)` | Parse RCL string, return Document |
| `parse_file_to_h(path)` | Parse file, return Hash |
| `parse_string_to_h(content)` | Parse string, return Hash |

### Document Class

| Method | Description |
|--------|-------------|
| `[](key)` | Get root value by key |
| `get(path)` | Get value by dot-notation path |
| `get_string(path, default)` | Get string value |
| `get_int(path, default)` | Get integer value |
| `get_float(path, default)` | Get float value |
| `get_bool(path, default)` | Get boolean value |
| `get_array(path)` | Get array value |
| `block(name)` | Get block by name |
| `has_key?(path)` | Check if key exists |
| `to_h` | Convert to Hash |
| `block_names` | Get all block names |
| `keys` | Get all root keys |

### Blocks Module

| Method | Description |
|--------|-------------|
| `register(name, &block)` | Register handler for block type |
| `registered?(name)` | Check if handler exists |
| `handler(name)` | Get handler for block type |
| `process(block)` | Process block with handler |
| `process_document(doc)` | Process all blocks in document |
| `clear` | Clear all handlers |
| `names` | Get registered handler names |

## License

MIT

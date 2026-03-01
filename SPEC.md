# RCL Language Specification

## Overview

RCL (Ruby-like Configuration Language) is a Ruby-inspired configuration language with a simple, readable syntax. It uses `do...end` blocks for nesting and `#` for comments.

## Lexical Structure

### Comments

Comments start with `#` and extend to the end of the line:

```rcl
# This is a comment
key = "value"  # Inline comment
```

### Whitespace

- Spaces and tabs are ignored except in strings
- Newlines separate statements
- Indentation is not significant

### Identifiers

Identifiers start with a letter or underscore, followed by letters, digits, or underscores:

```
identifier
server_port
_my_var
```

### Keywords

| Keyword | Description |
|---------|-------------|
| `do` | Opens a block |
| `end` | Closes a block |
| `true` | Boolean true (used as identifier) |
| `false` | Boolean false (used as identifier) |

## Grammar

```
program     ::= block*
block       ::= identifier do properties? blocks? end
properties  ::= property+
property    ::= identifier = value
blocks      ::= block+
value       ::= string | number | boolean | array
string      ::= " characters "
number      ::= integer | float
integer     ::= digit+
float       ::= integer . integer
boolean     ::= true | false
array       ::= [ values? ]
values      ::= value (, value)*
```

## Data Types

### Strings

Strings are enclosed in double quotes. Escape sequences:

| Escape | Character |
|--------|-----------|
| `\"` | Double quote |
| `\n` | Newline |
| `\t` | Tab |

```rcl
name = "John Doe"
path = "/usr/local/bin"
quoted = "He said \"hello\""
```

### Numbers

Integers and floating-point numbers:

```rcl
port = 8080
large = 12598959
ratio = 3.14
negative = -42
```

### Booleans

```rcl
enabled = true
disabled = false
```

### Arrays

```rcl
items = ["apple", "banana", "cherry"]
numbers = [1, 2, 3, 4, 5]
empty = []
```

### Blocks

Blocks group related configuration:

```rcl
server do
  host = "localhost"
  port = 3000
end
```

Nested blocks:

```rcl
server do
  host = "localhost"
  
  ssl do
    enabled = true
    cert = "/path/to/cert"
  end
end
```

## Examples

### Simple Configuration

```rcl
# Application settings
app do
  name = "MyApp"
  version = "1.0.0"
  debug = true
end
```

### Server Configuration

```rcl
server do
  address = "0.0.0.0"
  port = 8080
  
  ssl do
    enabled = true
    cert = "/etc/ssl/cert.pem"
    key = "/etc/ssl/key.pem"
  end
end
```

### Database Configuration

```rcl
database do
  host = "localhost"
  port = 5432
  name = "myapp"
  pool_size = 10
  timeout = 30.5
  
  credentials do
    username = "admin"
    password = "secret"
  end
end
```

### Array Values

```rcl
features = ["auth", "logging", "cache"]
allowed_hosts = ["localhost", "example.com"]
ports = [80, 443, 8080]
```

## Implementation Notes

### Token Types

| Type | Description |
|------|-------------|
| `Identifier` | Variable or block names |
| `String` | Quoted string literal |
| `Number` | Integer or float |
| `Equal` | `=` assignment operator |
| `Comma` | `,` array separator |
| `Do` | `do` keyword |
| `End` | `end` keyword |
| `LBracket` | `[` array start |
| `RBracket` | `]` array end |
| `EOF` | End of input |

### AST Nodes

- `Document` - Root node containing blocks
- `BlockNode` - Block with name, properties, and nested blocks
- `StringNode` - String value
- `NumberNode` - Numeric value (Int32, Int64, or Float64)
- `BooleanNode` - Boolean value
- `ArrayNode` - Array of values

### Error Handling

The parser raises errors for:
- Unexpected tokens
- Missing `end` for blocks
- Missing `]` for arrays
- Invalid escape sequences

## Version History

### 1.0.0

- Initial release
- Ruby-like block syntax
- Type-safe value parsing
- Custom block handlers

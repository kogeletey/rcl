# RCL Language Specification

## 1. Overview

RCL (Ruby-like Configuration Language) is a configuration DSL with explicit `do ... end` blocks,
assignment-based properties, and typed scalar/array values.

This specification defines:

- lexical rules
- grammar
- AST and hash projection rules
- conversion rules to YAML/TOML/HCL
- error expectations

## 2. Lexical Structure

### 2.1 Whitespace

- Spaces, tabs, and newlines are allowed between tokens.
- Newlines do not have semantic meaning by themselves.

### 2.2 Comments

- Only `#` line comments are supported.
- Everything from `#` to end-of-line is ignored.

Example:

```rcl
# top-level comment
server do
  port = 8080 # inline comment
end
```

### 2.3 Identifiers

- Must start with `[A-Za-z_]`
- Continue with `[A-Za-z0-9_]`

### 2.4 Strings

- Only double-quoted strings are valid: `"..."`
- Supported escapes: `\"`, `\\`, `\n`, `\t`
- Single-quoted strings are invalid syntax.

### 2.5 Numbers

- Integer: `123`, `-42`
- Float: `3.14`, `-0.5`

### 2.6 Booleans

- `true`
- `false`

## 3. Grammar

```ebnf
program         ::= block*
block           ::= identifier argument? "do" statement* "end"
argument        ::= string
statement       ::= property | block
property        ::= property_key "=" value
property_key    ::= identifier ("." identifier)*
value           ::= string | number | boolean | array
array           ::= "[" (value ("," value)*)? "]"
```

## 4. Data Model

## 4.1 AST Nodes

- `Document`
- `BlockNode`
- `StringNode`
- `NumberNode`
- `BooleanNode`
- `ArrayNode`

## 4.2 Hash Projection (`to_h`)

`Document#to_h` projects AST into nested maps/arrays/scalars.

### 4.2.1 Properties

`key = value` becomes:

```json
{ "key": value }
```

### 4.2.2 Dotted keys

`tls.cert_path = "/etc/cert.pem"` stays literal:

```json
{ "tls.cert_path": "/etc/cert.pem" }
```

### 4.2.3 Regular blocks

```rcl
server do
  port = 8080
end
```

becomes:

```json
{ "server": { "port": 8080 } }
```

### 4.2.4 Named blocks (argument blocks)

Any block with string argument is projected as `name -> arg -> object`.

```rcl
region "us" do
  name = "My name"
end
```

becomes:

```json
{ "region": { "us": { "name": "My name" } } }
```

Multiple argument blocks merge under same base key:

```rcl
region "us" do
  name = "US"
end
region "eu" do
  name = "EU"
end
```

becomes:

```json
{
  "region": {
    "us": { "name": "US" },
    "eu": { "name": "EU" }
  }
}
```

## 5. Formatting

Canonical formatter emits:

- double-quoted strings
- explicit `do ... end` block structure
- array literals with comma separators

## 6. Native Conversion

RCL provides native conversion from projected hash model to:

- YAML (`to_yaml`)
- TOML (`to_toml`)
- HCL (`to_hcl`)

### 6.1 Conversion invariants

- Named blocks must stay `name -> arg -> object`.
- Dotted keys remain literal keys.
- Scalar values preserve type (`string`, `number`, `bool`).

## 7. Errors

Parser must fail on:

- unexpected token
- unterminated string
- invalid escape sequence
- missing `end`
- missing `]`
- use of unsupported string form (single quotes)

Error messages should include line and column where available.

## 8. Compatibility Notes

- `#` comments are supported.
- `//` comments are not part of the language.
- Single-quoted strings are not part of the language.

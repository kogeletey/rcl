# Tree-sitter Grammar for RCL

Ruby-like Configuration Language parser for Tree-sitter.

## Installation

### Prerequisites

```bash
# Install Node.js and npm
# Install tree-sitter CLI
npm install -g tree-sitter-cli
```

### Build Parser

```bash
cd grammar
npm install
tree-sitter generate
```

### Test Parser

```bash
tree-sitter test
tree-sitter parse ../config.rcl.example
```

## Usage in Neovim

### Option 1: Using nvim-treesitter

Add to your Neovim config:

```lua
require('nvim-treesitter.configs').setup {
  ensure_installed = { "rcl" },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
}

-- Add custom parser path
local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.rcl = {
  install_info = {
    url = "/path/to/vless/grammar",
    files = {"src/parser.c"},
    branch = "main",
  },
  filetype = "rcl",
}
```

### Option 2: Manual Installation

```bash
# Build the parser
cd grammar
tree-sitter generate
tree-sitter build --wasm

# Copy to Neovim parser directory
cp src/parser.so ~/.local/share/nvim/lazy/nvim-treesitter/parser/rcl.so
```

## Grammar Rules

```
source_file → statement*
statement → block | assignment
block → identifier string? DO statement* END
assignment → property_key EQUAL value
property_key → identifier ("." identifier)*
value → string | number | boolean | array
string → "..."
number → -?digits(.digits)?
boolean → true | false
array → [value, ...]
identifier → [A-Za-z_][A-Za-z0-9_]*
comment → #...
```

## Example

```rcl
config do
  enabled = true
  port = 8080
  tls.cert_path = "/etc/cert.pem"
  region "us" do
    name = "My Name"
  end
end
```

## Development

```bash
# Generate parser
tree-sitter generate

# Run tests
tree-sitter test

# Parse a file
tree-sitter parse file.rcl

# Test highlighting
tree-sitter highlight file.rcl
```

## License

MIT

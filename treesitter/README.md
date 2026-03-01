# Tree-sitter Grammar for RCL

Ray Configuration Language parser for Tree-sitter.

## Installation

### Prerequisites

```bash
# Install Node.js and npm
# Install tree-sitter CLI
npm install -g tree-sitter-cli
```

### Build Parser

```bash
cd treesitter
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
    url = "/path/to/vless/treesitter",
    files = {"src/parser.c"},
    branch = "main",
  },
  filetype = "rcl",
}
```

### Option 2: Manual Installation

```bash
# Build the parser
cd treesitter
tree-sitter generate
tree-sitter build --wasm

# Copy to Neovim parser directory
cp src/parser.so ~/.local/share/nvim/lazy/nvim-treesitter/parser/rcl.so
```

## Grammar Rules

```
source_file → statement*
statement → block | assignment
block → identifier DO statement* END
assignment → identifier EQUAL value
value → string | number | array
string → "..."
number → digits
array → [value, ...]
identifier → alphanumeric
comment → #... or //...
```

## Example

```rcl
xray do
  server_address = "provider.boogle.cloud"
  server_port = 32185
  
  users = ["a@b.com", "c@d.com"]
  
  akash do
    deployment_name = "service-1"
    pricing_amount = 18
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

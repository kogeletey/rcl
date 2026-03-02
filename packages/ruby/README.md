# rcl-ruby

> Under Construction, need help with this

Ruby parser/formatter package for RCL.

## Install

```bash
gem install rcl-ruby
```

## Usage

```ruby
require "rcl"

ast = RCL.parse("xray do\n  port = 8080\nend")
puts ast["kind"]
puts RCL.format(ast)
```

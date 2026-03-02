# rcl-ruby

> Under Construction, need help with this

Ruby parser/formatter/converter package for RCL.

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
puts RCL.to_object(ast)
puts RCL.to_yaml(ast)
puts RCL.to_toml(ast)
puts RCL.to_hcl(ast)
```

Constraints: `#` comments only, strings in double quotes only, dotted keys are nested, duplicate/conflicting keys fail.

# rcl-ruby

> Under Construction, need help with this

Ruby parser/formatter/converter package for RCL.

## Install

```bash
gem install rcl-ruby
```

## Usage

Core entrypoint (`require "rcl/core"`) includes only parse + object projection.

```ruby
require "rcl/core"

ast = RCL::Core.parse("xray do\n  port = 8080\nend")
puts ast["kind"]
puts RCL::Core.to_object(ast)
```

Extended entrypoint (`require "rcl"`) preserves the existing full API.

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

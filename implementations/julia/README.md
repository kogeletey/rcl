# rcl-julia

Julia implementation for RCL native implementation.

## API

Core entrypoint (`RCLCore`, from `src/RCLCore.jl`) includes only parse + object projection.

```julia
include("src/RCLCore.jl")
using .RCLCore

ast = RCLCore.parse("xray do\n  port = 8080\nend")
obj = RCLCore.to_object("xray do\n  port = 8080\nend")
```

- `RCLCore.parse(String)`
- `RCLCore.to_object(String|AST)`

Extended entrypoint (`RCL`, from `src/RCL.jl`) preserves the existing full API.

```julia
include("src/RCL.jl")
using .RCL

formatted = RCL.format("xray do\n  port = 8080\nend")
yaml = RCL.to_yaml("xray do\n  port = 8080\nend")
```

- `RCL.parse(String)`
- `RCL.format(String|AST)`
- `RCL.to_object(String|AST)`
- `RCL.to_yaml(String|AST)`
- `RCL.to_toml(String|AST)`
- `RCL.to_hcl(String|AST)`

# rcl-ocaml

OCaml implementation for RCL native implementation.

Core entrypoint: `Rcl.Core` with `parse`, AST/types (`num`, `node`, `block`, `document`, `value`), and `to_object`.

Extended/backward-compatible entrypoint: `Rcl` with formatter/converters (`format_rcl`, `to_yaml`, `to_toml`, `to_hcl`).

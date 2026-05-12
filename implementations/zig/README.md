# rcl-zig

Zig implementation for RCL native implementation.

Core entrypoint: `core.zig` exposes `parse`, AST/types (`Doc`, `Block`, `Value`, `ParseError`), and `to_object`.

Extended/backward-compatible entrypoint: `rcl.zig` keeps formatter/converters (`format`, `toObject`, `toYAML`, `toTOML`, `toHCL`).

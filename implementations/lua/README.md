# rcl-lua

Lua implementation for RCL native implementation.

Core entrypoint: `rcl/core.lua` with `parse`, AST `types`, and `toObject`/`to_object`.

Extended/backward-compatible entrypoint: `rcl.lua` (or `rcl/extended.lua`) with `parse`, `format`, `toObject`, `toYAML`, `toTOML`, `toHCL`.

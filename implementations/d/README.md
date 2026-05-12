# rcl-d

D implementation for RCL native implementation.

Core entrypoint: `import rcl.core;` exposes `parse`, AST/types (`rcl.ast`), and `toObject`/`to_object`.

Extended/backward-compatible entrypoint: `import rcl;` keeps formatter/converters (`formatRcl`, `toYAML`, `toTOML`, `toHCL`).

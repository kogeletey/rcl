# shards/actions

RCL-based workflow generation.

## Generate workflows

```bash
crystal run shards/actions/scripts/generate_workflows.cr
```

## Convert arbitrary RCL to yml/toml/hcl

```bash
crystal run shards/actions/scripts/convert_rcl.cr -- --input shards/actions/workflows/ci.rcl --format yml
```

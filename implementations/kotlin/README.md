# rcl-kotlin

> Under Construction, need help with this

Kotlin/JVM parser/formatter/converter for full RCL spec.

## Core API (`io.rcl.core.RCL`)

```kotlin
val ast = io.rcl.core.RCL.parse(source)
val obj = io.rcl.core.RCL.toObject(ast)
```

## Extended API (`io.rcl.RCL`)

```kotlin
val ast = RCL.parse(source)
val out = RCL.format(ast)
val yaml = RCL.toYaml(ast)
val toml = RCL.toToml(ast)
val hcl = RCL.toHcl(ast)
```

Constraints: `#` comments only, strings in double quotes only, dotted keys are nested, duplicate/conflicting keys fail.

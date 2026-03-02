# rcl-kotlin

> Under Construction, need help with this

Kotlin/JVM parser/formatter/converter for full RCL spec.

## Usage

```kotlin
val ast = Parser.parse(source)
val obj = Converters.toObject(ast)
val yaml = Converters.toYaml(ast)
val toml = Converters.toToml(ast)
val hcl = Converters.toHcl(ast)
val out = Formatter.format(ast)
```

Constraints: `#` comments only, strings in double quotes only, dotted keys are nested, duplicate/conflicting keys fail.

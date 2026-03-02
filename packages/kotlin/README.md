# rcl-kotlin

> Under Construction, need help with this

Kotlin/JVM parser/formatter for full RCL spec.

## Features

- Full lexer/parser for RCL grammar
- Position-aware parse errors
- Canonical formatter and roundtrip tests

## Usage

```kotlin
val ast = Parser.parse(source)
val out = Formatter.format(ast)
```

## Test

```bash
mvn test
```

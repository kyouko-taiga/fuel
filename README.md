# Fuel

Fuel is a compiler toolchain designed to ease the implementation of frontend-agnostic memory safety analysis techniques. It is designed aroung Fuel IR, a low-level, assembly-inspired programming language that aims to provide a suitable framework to reason about memory safety properties.

Fuel IR is equipped with a gradual flow-sensitive type system, based on [type capabilities](https://doi.org/10.1007/3-540-46425-5_24).
This type system can track assumptions about the state of the memory across all instructions, which can be used to express various properties.

Consider for instance the following snippet in C:
```c
int  foo;
int* bar = &foo;
int  ham = *bar;
foo = 1337;
```
In Fuel IR, the equivalent program would **not** grant type `int*` to `ham` until `foo` is assigned to a value at line 4.
Hence, the declaration at line 3 would be illegal.

## Tests

Most tests are ran against actual Fuel IR code.
Test cases are defined as source files in human-readable format, annotated with a special DSL to describe expected diagnostics. 

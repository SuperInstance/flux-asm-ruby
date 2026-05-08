# Flux ASM

Pure Ruby FLUX ISA v3.0 toolchain: **assembler**, **disassembler**, and **reference VM**.

> ⚠️ **Superseded by `superinstance-flux-runtime`** — this repo provides a lightweight standalone assembler/disassembler, but a full-featured version is included in [`superinstance-flux-runtime`](https://github.com/SuperInstance/superinstance-flux-runtime-ruby) (published gem `superinstance-flux-runtime`). Consider using the runtime for the most complete opcode table and execution environment.

Designed for scripting agent coordination, bytecode inspection, and FLUX program development in Ruby.

## Install

```bash
gem install flux-asm
```

Or in your Gemfile:

```ruby
gem 'flux-asm'
```

## Quick Start

```ruby
require 'flux-asm'

# Assemble a program
asm = Flux::Assembler.new
bytecode, errs = asm.assemble <<~ASM
  MOVI R0, 10
  MOVI R1, 20
  IAdd R2, R0, R1
  RET
ASM
fail(errs.inspect) unless errs.empty?

# Run it
vm = Flux::VM.new
vm.load(bytecode).run
puts vm.gp[2]   # => 30
puts vm.exit_code  # => 0

# Inspect it
puts Flux::Disassembler.new.disassemble(bytecode)
# MOVI R0, 10
# MOVI R1, 20
# IAdd R2, R0, R1
# RET
```

## Architecture

```
lib/flux-asm/
  flux-asm.rb           # Main require + VERSION
  flux-asm/
    opcodes.rb          # FLUX ISA v3.0 opcode table + lookup helpers
    assembler.rb       # Text assembly → binary bytecode
    disassembler.rb    # Binary bytecode → text assembly
    vm.rb              # Reference execution engine
```

## Opcode Support

Core subset of FLUX ISA v3.0:
- **Arithmetic**: `NOP`, `IAdd`, `ISub`, `IMul`, `IDiv`, `IRem`, `INeg`, `IAbs`
- **Logical**: `IAnd`, `IOr`, `IXor`, `INot`, `ISHL`, `ISHR`, `ISAR`
- **Compare**: `ICmp`, `ICmpGT`, `ICmpGE`, `ICmpEQ`, `ICmpNE`
- **Branch**: `Jmp`, `Jnz`, `Jz`
- **Move**: `Mov`, `MOVI`, `MOVF`
- **Memory**: `MEM.load`, `MEM.store`, `MEM.copy`
- **Control**: `CALL`, `RET`, `SYNC.fork`, `SYNC.yield`
- **I/O**: `IO.pulse`, `IO.poll`, `HANDSAKE`

## Design Principles

- **No dependencies** — pure Ruby, stdlib only
- **4-byte fixed-width instructions** — matches FLUX ISA v3.0 encoding
- **Reference VM** — not optimized, written for clarity and determinism
- **Scriptable** — designed for code generation, not just program execution

## License

MIT

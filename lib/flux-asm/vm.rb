# frozen_string_literal: true

require_relative 'opcodes'
require_relative 'assembler'
require_relative 'disassembler'

module Flux
  ##
  # Reference FLUX ISA v3.0 virtual machine (pure Ruby)
  #
  # @example
  #   code = Flux::Assembler.new.assemble <<~ASM
  #     MOVI R0, 10
  #     MOVI R1, 20
  #     IAdd R2, R0, R1
  #     RET
  #   ASM.first
  #   vm = Flux::VM.new
  #   vm.load(code).run
  #   puts vm.gp[2]  # => 30
  class VM
    GP_SIZE  = 16
    FP_SIZE  = 16

    attr_reader :gp, :fp, :pc

    def initialize
      @gp  = [0] * GP_SIZE
      @fp  = [0.0] * FP_SIZE
      @pc  = 0
      @halted   = false
      @exit_code = 0
      @memory   = {}
    end

    def load(bytecode)
      @bytecode = bytecode.bytes
      @pc  = 0
      @halted = false
      self
    end

    def halted?
      @halted
    end

    def exit_code
      @halted ? @exit_code : nil
    end

    def run
      @halted = false
      while !@halted && @pc < @bytecode.length
        step
      end
      self
    end

    def step
      ins = @bytecode[@pc, 4]
      return halt!(1) unless ins&.length == 4

      opcode = ins[0]
      a = ins[1]
      b = ins[2]
      c = ins[3]

      case opcode
      # Arithmetic
      when 0x00 then @pc += 4  # NOP
      when 0x01 then @gp[a] = @gp[b] + @gp[c];  @pc += 4
      when 0x02 then @gp[a] = @gp[b] - @gp[c];  @pc += 4
      when 0x03 then @gp[a] = @gp[b] * @gp[c];  @pc += 4
      when 0x04 then @gp[a] = @gp[b] / @gp[c];  @pc += 4
      when 0x05 then @gp[a] = @gp[b] % @gp[c];  @pc += 4
      when 0x06 then @gp[a] = -@gp[b];           @pc += 4
      when 0x07 then @gp[a] = @gp[b].abs;         @pc += 4

      # Logical
      when 0x10 then @gp[a] = @gp[b] & @gp[c];  @pc += 4
      when 0x11 then @gp[a] = @gp[b] | @gp[c];  @pc += 4
      when 0x12 then @gp[a] = @gp[b] ^ @gp[c];  @pc += 4
      when 0x13 then @gp[a] = ~@gp[b];           @pc += 4
      when 0x14 then @gp[a] = @gp[b] << @gp[c]; @pc += 4
      when 0x15 then @gp[a] = @gp[b] >> @gp[c]; @pc += 4
      when 0x16 then @gp[a] = @gp[b] >> @gp[c]; @pc += 4  # SAR

      # Compare
      when 0x20 then @gp[a] = (@gp[b] <=> @gp[c]); @pc += 4
      when 0x21 then @gp[a] = (@gp[b] >  @gp[c] ? 1 : 0); @pc += 4
      when 0x22 then @gp[a] = (@gp[b] >= @gp[c] ? 1 : 0); @pc += 4
      when 0x23 then @gp[a] = (@gp[b] == @gp[c] ? 1 : 0); @pc += 4
      when 0x24 then @gp[a] = (@gp[b] != @gp[c] ? 1 : 0); @pc += 4
      when 0x25 then @pc = b * 4                             # Jmp
      when 0x26 then @pc = (@gp[b] != 0) ? (c * 4) : (@pc + 4)  # Jnz
      when 0x27 then @pc = (@gp[b] == 0) ? (c * 4) : (@pc + 4)  # Jz

      # Move
      when 0x30 then @gp[a] = @gp[b];           @pc += 4
      when 0x31 then @gp[a] = b;                @pc += 4
      when 0x32 then @fp[a] = Float(b);         @pc += 4

      # Memory
      when 0x40 then @gp[a] = @memory[@gp[b] + c] || 0; @pc += 4
      when 0x41 then @memory[@gp[b] + c] = @gp[a];      @pc += 4
      when 0x42 then @memory[@gp[a] = @gp[b]] = @gp[c]; @pc += 4

      # Control
      when 0x50 then @pc = b * 4  # CALL (simpler: direct PC jump)
      when 0x51 then halt!(0)     # RET
      when 0x52 then @pc += 4     # SYNC.fork (no-op in reference VM)
      when 0x53 then @pc += 4     # SYNC.yield (no-op)

      # I/O
      when 0x60 then @pc += 4  # IO.pulse (stub)
      when 0x61 then @gp[a] = 0; @pc += 4  # IO.poll (stub)
      when 0x62 then @pc += 4  # HANDSAKE (stub)

      else
        @pc += 4
      end
    end

    private

    def halt!(code)
      @halted = true
      @exit_code = code
    end
  end
end

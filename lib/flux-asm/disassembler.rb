# frozen_string_literal: true

require_relative 'opcodes'

module Flux
  ##
  # Disassembler: binary FLUX bytecode → text assembly
  #
  # @example
  #   dis = Flux::Disassembler.new
  #   source = dis.disassemble(bytecode)
  #   puts source
  class Disassembler
    def disassemble(bytecode)
      lines = []
      bytecode.bytes.each_slice(4) do |ins|
        opcode = ins[0]
        meta = Flux::OPCODES[opcode]
        unless meta
          lines << "DB  0x#{opcode.to_s(16).upcase}"
          next
        end
        mnemonic = meta[0]
        fmt = meta[2]
        parts = [mnemonic.ljust(12)]

        case fmt
        when 'RRR'
          parts << "R#{ins[1]}, R#{ins[2]}, R#{ins[3]}"
        when 'RR'
          parts << "R#{ins[1]}, R#{ins[2]}"
        when 'R'
          parts << "R#{ins[1]}"
        when 'RI'
          parts << "R#{ins[1]}, #{ins[2]}"
        when 'RFI'
          parts << "R#{ins[1]}, #{ins[2]}"
        when 'RRA'
          parts << "R#{ins[1]}, R#{ins[2]}, #{ins[3]}"
        when 'BR'
          parts << ":#{ins[1]}"
        when 'BRR'
          parts << ":#{ins[1]}, R#{ins[2]}, R#{ins[3]}"
        when 'CALL'
          parts << "0x#{ins[1].to_s(16).upcase}"
        end

        lines << parts.join(' ')
      end
      lines.join("\n")
    end
  end
end

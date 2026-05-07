# frozen_string_literal: true

require_relative 'opcodes'

module Flux
  ##
  # Assembler: text FLUX assembly → binary bytecode
  #
  # @example
  #   asm = Flux::Assembler.new
  #   bytecode = asm.assemble <<~ASM
  #     MOVI R0, 42
  #     MOVI R1, 8
  #     IAdd R2, R0, R1
  #     RET
  #   ASM
  #   vm = Flux::VM.new
  #   vm.load(bytecode).run
  #   puts vm.gp[2]  # => 50
  class Assembler
    attr_reader :errors

    def initialize
      @errors = []
      @labels = {}
      @pending = []  # [label_name, pc_after_this_instruction]
    end

    ##
    # Assemble a program from source string.
    # Returns [bytecode, errors]
    def assemble(source)
      @errors.clear
      @labels.clear
      @pending.clear
      instructions = []

      source.lines.each_with_index do |line, lineno|
      next if line.strip.empty? || line.strip.start_with?('#')
      lineno_base = lineno + 1

      line = line.strip.sub(/\s+;.*/, '')  # strip comments
      tokens = line.gsub(/\s+/, ' ').split(' ')
      mnemonic = tokens[0]
      args = tokens[1..].map { |a| a.tr(',', '').strip }.compact
      opcode = Flux.opcode_for(mnemonic)
      unless opcode
        @errors << "Line #{lineno_base}: unknown opcode #{mnemonic}"
        next
      end

      enc = encode(opcode, args, lineno_base)
      if enc
        instructions << enc
      else
        @errors << "Line #{lineno_base}: can't encode #{mnemonic} with args #{args.inspect}"
      end
      end

      return ["".b, @errors] unless @errors.empty?

      # Fix branch targets
      fix_branches!(instructions)

      bytecode = instructions.map { |ins| ins.pack('C*') }.join
      [bytecode, []]
    end

    private

    def encode(opcode, args, lineno)
      fmt = Flux::OPCODES[opcode][2]
      ins = [opcode]

      case fmt
      when 'RRR'
        raise_if_wrong_count(args, 3, lineno)
        3.times { |i| ins << parse_reg(args[i], lineno) }
      when 'RR'
        raise_if_wrong_count(args, 2, lineno)
        ins << parse_reg(args[0], lineno)
        ins << parse_reg(args[1], lineno)
        ins << 0
      when 'R'
        ins << parse_reg(args[0], lineno)
        ins << 0
        ins << 0
      when 'RI'
        raise_if_wrong_count(args, 2, lineno)
        ins << parse_reg(args[0], lineno)
        ins << parse_imm(args[1], lineno)
        ins << 0
      when 'RFI'
        ins << parse_reg(args[0], lineno)
        ins << parse_imm(args[1], lineno)
        ins << 0
      when 'RRA'
        raise_if_wrong_count(args, 3, lineno)
        ins << parse_reg(args[0], lineno)
        ins << parse_reg(args[1], lineno)
        ins << parse_imm(args[2], lineno)
      when 'BR'
        ins << parse_imm(args[0], lineno)
        ins << 0
        ins << 0
      when 'BRR'
        ins << parse_imm(args[0], lineno)
        ins << parse_reg(args[1], lineno)
        ins << parse_reg(args[2], lineno)
      when 'CALL'
        ins << parse_imm(args[0], lineno)
        ins << 0
        ins << 0
      when '.'  # no args
        ins << 0
        ins << 0
        ins << 0
      else
        raise "Unknown format #{fmt}"
      end

      ins
    end

    def raise_if_wrong_count(args, expected, lineno)
      return if args.length == expected
      @errors << "Line #{lineno}: expected #{expected} args, got #{args.length}"
    end

    def parse_reg(r, lineno)
      r = r.to_s.upcase
      case r
      when /\A(R\d{1,2}|A[0-3]|R[0-3]|S[0-5]|RP|PM)\z/
        $1[0] == 'R' ? $1[1..].to_i : register_index($1)
      else
        @errors << "Line #{lineno}: invalid register #{r}"
        0
      end
    end

    REGISTER_MAP = {
      'A0' => 0, 'A1' => 1, 'A2' => 2, 'A3' => 3,
      'R0' => 4, 'R1' => 5, 'R2' => 6, 'R3' => 7,
      'S0' => 8, 'S1' => 9, 'S2' => 10, 'S3' => 11,
      'S4' => 12, 'S5' => 13, 'RP' => 14, 'PM' => 15
    }.freeze

    def register_index(name)
      REGISTER_MAP.fetch(name) { raise ArgumentError, "Unknown register #{name}" }
    end

    def parse_imm(val, lineno)
      val = val.to_s.strip
      if val.start_with?('0x')
        val.to_i(16)
      elsif val =~ /\A-?\d+\z/
        val.to_i
      else
        @errors << "Line #{lineno}: can't parse immediate #{val}"
        0
      end
    end

    def fix_branches!(instructions)
      # Second pass: replace label references with PC offsets
      instructions.each do |ins|
        next unless ins[0] == 0x25 || ins[0] == 0x26 || ins[0] == 0x27  # Jmp/Jnz/Jz
        target_pc = @labels[ins[1]]
        if target_pc
          ins[1] = target_pc
        end
      end
    end
  end
end

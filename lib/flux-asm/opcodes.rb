# frozen_string_literal: true

# FLUX ISA v3.0 opcode table
# Each entry: [mnemonic, category, operand_format]
# Operand formats:
#   RRR  = Rd, Ra, Rb   (3 registers)
#   RR   = Rd, Ra       (2 registers)
#   R    = Rd           (1 register)
#   RI   = Rd, imm      (register + immediate)
#   RA   = Rd, addr     (register + address offset)
#   BR   = offset       (branch target)
#   CALL = slot         (jump table slot)

module Flux
  OPCODES = {
    # Arithmetic
    0x00 => %w[NOP      core    .    ],
    0x01 => %w[IAdd     core    RRR  ],
    0x02 => %w[ISub     core    RRR  ],
    0x03 => %w[IMul     core    RRR  ],
    0x04 => %w[IDiv     core    RRR  ],
    0x05 => %w[IRem     core    RRR  ],
    0x06 => %w[INeg     core    RR   ],
    0x07 => %w[IAbs     core    RR   ],

    # Logical
    0x10 => %w[IAnd     logic   RRR  ],
    0x11 => %w[IOr      logic   RRR  ],
    0x12 => %w[IXor     logic   RRR  ],
    0x13 => %w[INot     logic   RR   ],
    0x14 => %w[ISHL     logic   RRR  ],
    0x15 => %w[ISHR     logic   RRR  ],
    0x16 => %w[ISAR     logic   RRR  ],

    # Compare & branch
    0x20 => %w[ICmp     compare RRR  ],
    0x21 => %w[ICmpGT   compare RRR  ],
    0x22 => %w[ICmpGE   compare RRR  ],
    0x23 => %w[ICmpEQ   compare RRR  ],
    0x24 => %w[ICmpNE   compare RRR  ],
    0x25 => %w[Jmp      branch  BR   ],
    0x26 => %w[Jnz      branch  BRR  ],
    0x27 => %w[Jz       branch  BRR  ],

    # Move
    0x30 => %w[Mov      move    RRR  ],
    0x31 => %w[MOVI     move    RI   ],
    0x32 => %w[MOVF     move    RFI  ],

    # Memory
    0x40 => %w[MEM.load  mem     RRA  ],
    0x41 => %w[MEM.store mem     RRA  ],
    0x42 => %w[MEM.copy  mem     RRR  ],

    # Control
    0x50 => %w[CALL     control CALL ],
    0x51 => %w[RET      control .    ],
    0x52 => %w[SYNC.fork control .    ],
    0x53 => %w[SYNC.yield control .   ],

    # I/O & A2A
    0x60 => %w[IO.pulse io      RR   ],
    0x61 => %w[IO.poll  io      RR   ],
    0x62 => %w[HANDSAKE a2a     RI   ],
  }.freeze

  OPCODE_LOOKUP = OPCODES.transform_values { |v| v[0] }.invert.freeze

  def self.opcode_for(name)
    OPCODE_LOOKUP[name]
  end

  def self.mnemonic_for(opcode)
    return nil unless OPCODES[opcode]
    OPCODES[opcode][0]
  end

  def self.category_for(opcode)
    return nil unless OPCODES[opcode]
    OPCODES[opcode][1]
  end
end

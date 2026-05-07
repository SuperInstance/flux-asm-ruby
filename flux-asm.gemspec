Gem::Specification.new do |s|
  s.name = 'flux-asm'
  s.version = '0.1.0'
  s.summary = 'FLUX ISA v3 assembler, disassembler, and reference VM in pure Ruby'
  s.description = <<~DESC
    Pure Ruby implementation of the FLUX ISA v3.0 virtual machine.
    Includes a text assembler, bytecode disassembler, binary loader,
    and reference execution engine. Designed for FLUX bytecode
    generation, inspection, and agent coordination scripting.
  DESC
  s.authors = ['SuperInstance']
  s.email = 'engineering@superinstance.dev'
  s.license = 'MIT'
  s.homepage = 'https://github.com/SuperInstance/flux-asm-ruby'
  s.files = Dir['lib/**/*.rb']
  s.required_ruby_version = '>= 3.0'
end

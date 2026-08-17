# opcodes.rb
#
# Single source of truth for the SAP-1 instruction set.
#
#   * assembler.rb requires this file directly to build its OPS table.
#   * gen_decoder.rb requires this file to render Instruction_Decoder.v.erb
#     into Instruction_Decoder.v.
# Note that changes to this file require re-assembling
#
# Step 0 and step 1 are the universal instruction fetch and are emitted
# by the generator itself, not listed per-opcode:
#   step 0: MI CO CE      (memory_address <= PC)
#   step 1: RO II         (instruction <= RAM[memory_address], PC <= PC+1)

# Must match the INSTRUCTION_STEPS parameter default in Top.v /
# Instruction_Decoder.v -- there's no automated link between the two, this
# is just the Ruby-side half of that contract.
MAX_STEPS = 8

# ADD doesn't assert SU; SUB does. verb is used to build alu_addr /
# alu_immediate doc strings ("add A to RAM[addr]..." / "subtract A by an
# immediate...").
ALU_OPS = {
  ADD: { verb: 'add A to',      sub: false },
  SUB: { verb: 'subtract A by', sub: true }
}.freeze

# Which JIx mnemonic corresponds to which ALU flag.
COND_FLAGS = { zero: :JIZ, carry: :JIC, odd: :JIO }.freeze

module Templates
  module_function

  # step2: MAR <= embedded operand nibble (the address)
  # step3: A   <= RAM[MAR]
  def load_addr
    { argument: true,
      desc: 'load A from RAM[addr]',
      steps: {
        2 => %i[IO MI],
        3 => %i[RO AI]
      } }
  end

  # step2: MAR <= embedded operand nibble (the address)
  # step3: RAM[MAR] <= A
  def store_addr
    { argument: true,
      desc: 'store A into RAM[addr]',
      steps: {
        2 => %i[IO MI],
        3 => %i[AO RI]
      } }
  end

  # step2: MAR <= embedded operand nibble (the address)
  # step3: B   <= RAM[MAR]
  # step4: A   <= ALU(A op B), latch flags   (op: SU asserted only for SUB)
  def alu_addr(op:)
    info = ALU_OPS.fetch(op)
    { argument: true,
      desc: "#{info[:verb]} RAM[addr], storing into A. Clobbers B",
      steps: {
        2 => %i[IO MI],
        3 => %i[RO BI],
        4 => %i[EO AI EL] + (info[:sub] ? %i[SU] : [])
      } }
  end

  # step2: B <= embedded operand nibble (the immediate value)
  # step3: A <= ALU(A op B), latch flags
  def alu_immediate(op:)
    info = ALU_OPS.fetch(op)
    { argument: true,
      desc: "#{info[:verb]} an immediate 4-bit value, storing into A. Clobbers B",
      steps: {
        2 => %i[IO BI],
        3 => %i[EO AI EL] + (info[:sub] ? %i[SU] : [])
      } }
  end

  # step2: A <= embedded operand nibble (the immediate value)
  def load_immediate
    { argument: true,
      desc: 'load an immediate 4-bit value into A',
      steps: { 2 => %i[IO AI] } }
  end

  # step2: if the named flag is set, put the embedded operand nibble on
  # the bus and load it into PC (IO+J); either way, advance to the next
  # instruction.
  def conditional_jump(flag:)
    { argument: true,
      desc: "jump to addr if the #{flag} flag is set",
      steps: { 2 => { ctrl: [], cond: { flag: flag, ctrl: %i[IO J] } } } }
  end
end

# Builds one OPCODE_TABLE row. Just a thin wrapper so the loops below read
# as `entry(:NAME, template: ..., ...)` instead of repeating `{ name: ... }`
# hash syntax everywhere.
def entry(name, **kwargs)
  { name: name }.merge(kwargs)
end

# `steps:` step numbers map to one of:
#   - an Array of control-line symbols (:ADV is appended automatically to
#     the highest-numbered step, unless `no_adv: true` is set on the entry)
#   - a Hash `{ ctrl: [...], cond: { flag: :zero|:carry|:odd, ctrl: [...] } }`,
#     meaning: assert `ctrl` unconditionally, and ALSO assert `cond.ctrl`
#     if-and-only-if the named ALU flag is set. This is JIZ/JIC/JIO's
#     shape specifically -- nothing else in this ISA needs it.
#
# `template:` entries are expanded by expand_entry (below) using the
# Templates module above, which supplies both `steps:` and `desc:`.
# `desc:` on a table row is only needed for raw (non-templated) entries,
# or on the rare occasion you want to override what a template generated.
# Either way, the rendered comment is always "NAME - <desc>" -- the name
# itself is never repeated in the description text.

OPCODE_TABLE = [
  # NOP gets no dedicated `i_instruction ==` branch in the decoder -- any
  # opcode that isn't otherwise defined falls through to this behavior as
  # the implicit default case. It has to be index 0 for that reason.
  entry(:NOP, argument: false, steps: { 2 => %i[ADV] },
        desc: 'do nothing and just advance counter'),

  entry(:LDA, template: :load_addr),
  *ALU_OPS.each_key.map { |op| entry(op, template: :alu_addr, op: op) },
  entry(:LDI, template: :load_immediate),
  *ALU_OPS.each_key.map { |op| entry(:"#{op}I", template: :alu_immediate, op: op) },
  entry(:STA, template: :store_addr),

  entry(:JMP, argument: true, desc: 'jump to addr', steps: { 2 => %i[IO J] }),
  *COND_FLAGS.map { |flag, name| entry(name, template: :conditional_jump, flag: flag) },

  entry(:OUT, argument: false, desc: 'copy A to the output register', steps: { 2 => %i[AO OI] }),
  entry(:HLT, argument: false, no_adv: true, desc: 'halt the program', steps: { 2 => %i[HLT] })
].freeze

# Expands one OPCODE_TABLE row (template or raw) into
#   { name:, opcode:, argument:, desc:, steps: { n => { ctrl:, cond: } } }
# with :ADV automatically appended to the last step, unless no_adv: true.
# `desc:` on the table row always wins over what a template generated --
# that's the override escape hatch for the rare exception.
def expand_entry(row, opcode)
  base =
    if row[:template]
      kwargs = row.reject { |k, _| %i[name template desc no_adv].include?(k) }
      Templates.public_send(row[:template], **kwargs)
    else
      { argument: row.fetch(:argument), steps: row.fetch(:steps) }
    end

  steps = base[:steps].each_with_object({}) do |(n, v), h|
    h[n] = v.is_a?(Hash) ? { ctrl: v.fetch(:ctrl), cond: v[:cond] } : { ctrl: v, cond: nil }
  end

  unless row[:no_adv] || steps.empty?
    last = steps.keys.max
    steps[last][:ctrl] += [:ADV] unless steps[last][:ctrl].include?(:ADV)
  end

  desc = row[:desc] || base[:desc] || row.fetch(:name).to_s

  { name: row.fetch(:name), opcode: opcode, argument: base.fetch(:argument),
    desc: "#{row.fetch(:name)} - #{desc}", steps: steps }
end

# Memoized: `table` (OPCODE_TABLE) never changes at runtime, no reason to
# re-expand and re-validate it more than once no matter how many times
# callers ask for it. Takes the raw table explicitly (rather than reaching
# for the OPCODE_TABLE constant itself) so do_expand_and_validate stays
# testable against a hand-built table, the way validate_opcode_table! is.
@expanded_table = nil

def expand_opcode_table(table)
  @expanded_table = do_expand_and_validate(table) if @expanded_table.nil?
  @expanded_table
end

# The actual work behind expand_opcode_table: turn the raw table into its
# expanded form, then fail fast on it -- with every problem reported at
# once -- rather than letting a bad table quietly produce a broken
# assembler or a broken decoder that only shows up much later at
# simulation time.
def do_expand_and_validate(table)
  expanded = table.each_with_index.map { |row, i| expand_entry(row, i) }.freeze
  validate_opcode_table!(expanded)
  expanded
end

def validate_opcode_table!(table)
  errors = []

  table.group_by { |e| e[:name] }.each do |name, rows|
    errors << "duplicate instruction name #{name.inspect} (#{rows.size} occurrences)" if rows.size > 1
  end

  # Opcode collisions can't actually happen while opcode == array index,
  # but this stays cheap insurance against a future refactor that adds an
  # explicit opcode: override back in.
  table.group_by { |e| e[:opcode] }.each do |opcode, rows|
    next unless rows.size > 1

    errors << "opcode #{opcode} (0x#{opcode.to_s(16)}) used by multiple instructions: " \
               "#{rows.map { |r| r[:name] }.join(', ')}"
  end

  table.each do |e|
    e[:steps].each_key do |step|
      if step < 2
        errors << "#{e[:name]}: step #{step} is reserved for instruction fetch (steps 0-1) -- " \
                   'instructions must start at step 2'
      elsif step >= MAX_STEPS
        errors << "#{e[:name]}: step #{step} is >= MAX_STEPS (#{MAX_STEPS})"
      end
    end
  end

  # argument: is an independently hand-written fact on each template/row --
  # nothing about the shape of `steps:` forces it to agree with what the
  # microcode actually does. The reliable structural signal here is
  # whether IO (instruction register out -- puts the embedded operand
  # nibble on the bus) appears in any step, including inside a
  # conditional (cond:) block, since JIZ/JIC/JIO only assert IO there.
  table.each do |e|
    fetches_operand = e[:steps].values.any? do |s|
      s[:ctrl].include?(:IO) || (s[:cond] && s[:cond][:ctrl].include?(:IO))
    end
    if e[:argument] && !fetches_operand
      errors << "#{e[:name]}: argument: true, but no step asserts IO (instruction register out) -- " \
                 'argument: should probably be false'
    elsif !e[:argument] && fetches_operand
      errors << "#{e[:name]}: argument: false, but a step asserts IO (instruction register out) -- " \
                 'argument: should probably be true'
    end
  end

  return if errors.empty?

  raise "opcodes.rb: invalid OPCODE_TABLE:\n  - #{errors.join("\n  - ")}"
end

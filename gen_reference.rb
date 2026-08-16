#!/usr/bin/env ruby
# Renders a human-readable ASCII reference table of the instruction set
# set from opcodes.rb -- meant to be the thing people actually read to
# look up an opcode or mnemonic, instead of parsing Instruction_Decoder.v.
#
#   ./gen_reference.rb [output_path]
#
# output_path defaults to OPCODES.txt next to this script. Not a gem
# dependency: this hand-rolls a small table renderer in the same visual
# style as the `tty-table` gem (bordered cells, a row separator between
# every row, wrapped multi-line cells), using plain ASCII (+, -, |) for
# the borders rather than Unicode box-drawing characters, so the output
# renders identically everywhere regardless of locale/terminal/editor.

require_relative 'opcodes'

# The only thing that differs between this script's copy here and its
# copy in the SAP-2 repo -- everything else reads OPCODE_TABLE generically.
ARCH_NAME = 'SAP-1'

# Wrap width for the Description column. Some descriptions (POPPC's, in
# particular) are long -- capping the column keeps one verbose row from
# stretching every row in the table out to its width, and from making the
# whole table wider than a normal terminal.
DESC_WIDTH = 56

def wrap(text, width)
  lines = []
  line = +''
  text.split(' ').each do |word|
    candidate = line.empty? ? word : "#{line} #{word}"
    if candidate.length > width
      lines << line
      line = +word
    else
      line = candidate
    end
  end
  lines << line unless line.empty?
  lines
end

def border(widths)
  '+' + widths.map { |w| '-' * (w + 2) }.join('+') + '+'
end

def row(cells, widths)
  '| ' + cells.each_with_index.map { |c, i| c.ljust(widths[i]) }.join(' | ') + ' |'
end

table = expand_opcode_table(OPCODE_TABLE)

rows = table.map do |e|
  # expand_entry bakes "NAME - " onto the front of desc for the Verilog
  # comments; strip it back off here since the mnemonic already has its
  # own column in this table.
  desc = e[:desc].sub(/^#{Regexp.escape(e[:name].to_s)} - /, '')
  { opcode: e[:opcode], name: e[:name].to_s, argument: e[:argument] ? 'Yes' : 'No', desc: desc }
end

opcode_hex_digits = [(Math.log2(rows.map { |r| r[:opcode] }.max + 1) / 4).ceil, 2].max
widths = [
  [2 + opcode_hex_digits,                        'Opcode'.length].max,
  [rows.map { |r| r[:name].length }.max,        'Mnemonic'.length].max,
  [rows.map { |r| r[:argument].length }.max,        'Arg?'.length].max,
  [DESC_WIDTH,                              'Description'.length].max
]

out = []
out << "#{ARCH_NAME} instruction set reference -- generated from opcodes.rb, do not edit by hand."
out << "Regenerate with `make #{File.basename(ARGV[0] || 'OPCODES.txt')}` after changing opcodes.rb."
out << ''
out << border(widths)
out << row(['Opcode', 'Mnemonic', 'Arg?', 'Description'], widths)
out << border(widths)

rows.each do |r|
  opcode_str = format("0x%0#{opcode_hex_digits}x", r[:opcode])
  desc_lines = wrap(r[:desc], widths[3])
  desc_lines = [''] if desc_lines.empty?

  desc_lines.each_with_index do |line_text, i|
    lead = i.zero? ? [opcode_str, r[:name], r[:argument]] : ['', '', '']
    out << row(lead + [line_text], widths)
  end
  out << border(widths)
end
out[-1] = border(widths) # last row's separator doubles as the bottom border

output_path = ARGV[0] || File.join(__dir__, 'OPCODES.txt')
File.write(output_path, "#{out.join("\n")}\n")

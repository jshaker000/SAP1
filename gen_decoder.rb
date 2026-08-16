#!/usr/bin/env ruby
# Renders Instruction_Decoder.v from Instruction_Decoder.v.erb + opcodes.rb.
#
#   ./gen_decoder.rb [output_path]
#
# output_path defaults to Instruction_Decoder.v next to this script.

require 'erb'
require_relative 'opcodes'

def render_step(data)
  ctrl = data[:ctrl].map { |c| "c_#{c}" }.join(' | ')
  ctrl = 'ZERO_CW' if data[:ctrl].empty?

  return ctrl unless data[:cond]

  cond_ctrl = data[:cond][:ctrl].map { |c| "c_#{c}" }.join(' | ')
  "(i_#{data[:cond][:flag]} ? (#{cond_ctrl}) : ZERO_CW) | #{ctrl}"
end

table     = expand_opcode_table(OPCODE_TABLE)
nop_entry = table.find { |e| e[:name] == :NOP }
raise 'opcodes.rb must define a :NOP entry' unless nop_entry

template_path = File.join(__dir__, 'Instruction_Decoder.v.erb')
output_path   = ARGV[0] || File.join(__dir__, 'Instruction_Decoder.v')

erb = ERB.new(File.read(template_path), trim_mode: '-')
File.write(output_path, erb.result(binding))

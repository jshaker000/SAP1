// Combinational module that takes program counter and instruction and ALU
// flags and produces control logic

`default_nettype none

module Instruction_Decoder (
  i_instruction,
  i_step,
  i_zero,
  i_carry,
  i_odd,
  o_control_word
);

  parameter  INSTRUCTION_WIDTH  = 4;
  parameter  INSTRUCTION_STEPS  = 8;

  `include "instructions.vi"

  localparam STEP_WIDTH         = $clog2(INSTRUCTION_STEPS);

  input wire     [INSTRUCTION_WIDTH-1:0] i_instruction;
  input wire            [STEP_WIDTH-1:0] i_step;
  input wire                             i_zero;
  input wire                             i_odd;
  input wire                             i_carry;
  output wire   [CONTROL_WORD_WIDTH-1:0] o_control_word;

  assign o_control_word = // fetch, put prgm cntr in mem addr, fetch instruction, advance PC. All instructions start like this
                 i_step == 'h0 ? c_MI | c_CO        :
                 i_step == 'h1 ? c_RO | c_II | c_CE :
                // i_instruction == 4'h00 ? // unimplemented - defaults at bottom to NOP
                   i_instruction == 4'h01 ? // LDA - put data in RAM addr in A
                     i_step == 'h2      ? c_IO | c_MI        :
                     i_step == 'h3      ? c_RO | c_AI        :
                     c_ADV :
                   i_instruction == 4'h02 ? // ADD - add data from RAM addr to A
                     i_step == 'h2      ? c_IO | c_MI        :
                     i_step == 'h3      ? c_RO | c_BI        :
                     i_step == 'h4      ? c_EO | c_AI | c_EL :
                     c_ADV :
                   i_instruction == 4'h03 ? // SUBTRACT - subtract data from RAM addr to A
                     i_step == 'h2      ? c_IO | c_MI        :
                     i_step == 'h3      ? c_RO | c_BI        :
                     i_step == 'h4      ? c_EO | c_SU | c_AI | c_EL :
                     c_ADV :
                   i_instruction == 4'h04 ? // LDI - load an immediate 4 bit value to A
                     i_step == 'h2      ? c_IO | c_AI        :
                     c_ADV :
                   i_instruction == 4'h05 ? // ADDI - add an immediate 4 bit value to A
                     i_step == 'h2      ? c_IO | c_BI        :
                     i_step == 'h3      ? c_EO | c_AI | c_EL :
                     c_ADV :
                   i_instruction == 4'h06 ? // SUBTRACTI - subtract an immediate 4 bit value from A
                     i_step == 'h2      ? c_IO | c_BI        :
                     i_step == 'h3      ? c_EO | c_SU | c_AI | c_EL :
                     c_ADV :
                   i_instruction == 4'h07 ? // STA - store A in RAM
                     i_step == 'h2      ? c_IO | c_MI :
                     i_step == 'h3      ? c_AO | c_RI :
                     c_ADV :
                   i_instruction == 4'h08 ? // JMP - jump to ADDR
                     i_step == 'h2      ? c_IO | c_J  :
                     c_ADV :
                   i_instruction == 4'h09 ? // JIZ - jump to ADDR if last ALU op was 0
                     i_step == 'h2      ? i_zero  ? (c_IO | c_J) : c_ADV :
                     c_ADV :
                   i_instruction == 4'h0a ? // JIC - jump to ADDR if last ALU op carried
                     i_step == 'h2      ? i_carry ? (c_IO | c_J) : c_ADV :
                     c_ADV :
                   i_instruction == 4'h0b ? // JIO - jump to ADDR if last ALU op was odd
                     i_step == 'h2      ? i_odd   ? (c_IO | c_J) : c_ADV :
                     c_ADV :
                 // i_instruction == 4'h0c ? // unimplement - defaults at bottom to NOP
                 // i_instruction == 4'h0d ? // unimplement - defaults at bottom to NOP
                   i_instruction == 4'h0e ? // OUT - copy Areg to out reg
                     i_step == 'h2      ? c_AO | c_OI :
                     c_ADV :
                   i_instruction == 4'h0f ? // HALT PROGRAM
                     c_HLT :
                     c_ADV;                 // NOP - do nothing and just advance counter

endmodule

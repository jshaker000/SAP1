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

  `include "control_words.vi"

  localparam STEP_WIDTH = $clog2(INSTRUCTION_STEPS);

  localparam                    [0:0] X_NOT_ZERO_FOR_SHOULD_NEVER_REACH = 1'b0;
  localparam [CONTROL_WORD_WIDTH-1:0] SHOULD_NEVER_REACH                = {CONTROL_WORD_WIDTH{X_NOT_ZERO_FOR_SHOULD_NEVER_REACH ? 1'bx : 1'b0}};
  localparam [CONTROL_WORD_WIDTH-1:0] ZERO_CW                           = {CONTROL_WORD_WIDTH{1'b0}};

  input wire     [INSTRUCTION_WIDTH-1:0] i_instruction;
  input wire            [STEP_WIDTH-1:0] i_step;
  input wire                             i_zero;
  input wire                             i_odd;
  input wire                             i_carry;
  output wire   [CONTROL_WORD_WIDTH-1:0] o_control_word;

 
  assign o_control_word =
                 // Fetch, put prgm cntr in mem addr, fetch instruction, advance PC. All instructions start like this
                 // Also note, all instructions must end in a c_ADV to advance to the next instruction
                 i_step == 'h0 ? c_MI | c_CO        :
                 i_step == 'h1 ? c_RO | c_II | c_CE :
                   // i_instruction == 4'h00 ? // unimplemented - defaults at bottom to NOP
                   // LDA - put data in RAM addr in A
                   i_instruction == 4'h01 ?
                     i_step == 'h2      ? c_IO | c_MI         :
                     i_step == 'h3      ? c_RO | c_AI | c_ADV :
                     SHOULD_NEVER_REACH:
                   // ADD - add data from RAM addr to A, storing into A. Clobbers B
                   i_instruction == 4'h02 ?
                     i_step == 'h2      ? c_IO | c_MI        :
                     i_step == 'h3      ? c_RO | c_BI        :
                     i_step == 'h4      ? c_EO | c_AI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // SUBTRACT - subtract data from RAM addr to A, storing into A. Clobbers B
                   i_instruction == 4'h03 ?
                     i_step == 'h2      ? c_IO | c_MI        :
                     i_step == 'h3      ? c_RO | c_BI        :
                     i_step == 'h4      ? c_EO | c_SU | c_AI | c_EL  | c_ADV :
                     SHOULD_NEVER_REACH:
                   // LDI - load an immediate 4 bit value to A
                   i_instruction == 4'h04 ?
                     i_step == 'h2      ? c_IO | c_AI | c_ADV :
                     SHOULD_NEVER_REACH:
                   // ADDI - add an immediate 4 bit value to A, storing into A. Clobbers B
                   i_instruction == 4'h05 ?
                     i_step == 'h2      ? c_IO | c_BI        :
                     i_step == 'h3      ? c_EO | c_AI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // SUBTRACTI - subtract an immediate 4 bit value to A, storing into A. Clobbers B
                   i_instruction == 4'h06 ?
                     i_step == 'h2      ? c_IO | c_BI        :
                     i_step == 'h3      ? c_EO | c_SU | c_AI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // STA - store A in RAM addr
                   i_instruction == 4'h07 ?
                     i_step == 'h2      ? c_IO | c_MI :
                     i_step == 'h3      ? c_AO | c_RI | c_ADV :
                     SHOULD_NEVER_REACH:
                   // JMP - jump to addr
                   i_instruction == 4'h08 ?
                     i_step == 'h2      ? c_IO | c_J  | c_ADV :
                     SHOULD_NEVER_REACH:
                   // JIZ - jump to addr if last ALU op was 0
                   i_instruction == 4'h09 ?
                     i_step == 'h2      ? (i_zero  ? (c_IO | c_J) : ZERO_CW) | c_ADV :
                     SHOULD_NEVER_REACH :
                   // JIC - jump to addr if last ALU op had a carry
                   i_instruction == 4'h0a ?
                     i_step == 'h2      ? (i_carry ? (c_IO | c_J) : ZERO_CW) | c_ADV :
                     SHOULD_NEVER_REACH :
                   // JIO - jump to ADDR if last ALU op was odd
                   i_instruction == 4'h0b ? // JIO - jump to ADDR if last ALU op was odd
                     i_step == 'h2      ? (i_odd   ? (c_IO | c_J) : ZERO_CW) | c_ADV :
                     SHOULD_NEVER_REACH :
                   // i_instruction == 4'h0c ? // unimplement - defaults at bottom to NOP
                   // i_instruction == 4'h0d ? // unimplement - defaults at bottom to NOP
                   // OUT - copy Areg to out reg
                   i_instruction == 4'h0e ?
                     i_step == 'h2      ? c_AO | c_OI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // HALT PROGRAM
                   i_instruction == 4'h0f ?
                     i_step == 'h2 ? c_HLT :
                     SHOULD_NEVER_REACH :
                   // NOP - do nothing and just advance counter
                  i_step == 'h2 ? c_ADV : SHOULD_NEVER_REACH;
endmodule

// Combinational module that takes program counter and instruction and ALU
// flags and produces control logic

`default_nettype none

module Instruction_Decoder #(
  parameter  INSTRUCTION_WIDTH  = 4,
  parameter  INSTRUCTION_STEPS  = 8,
  parameter  CONTROL_WORD_WIDTH = 17,
  localparam STEP_WIDTH         = $clog2(INSTRUCTION_STEPS)
)(
  input wire  [INSTRUCTION_WIDTH-1:0] i_instruction,
  input wire         [STEP_WIDTH-1:0] i_step,
  input wire                          i_zero,
  input wire                          i_carry,
  input wire                          i_odd,

  output wire                     o_halt,         // halt
  output wire                     o_adv,          // advance instruction counter to next instruction
  output wire                     o_memaddri,     // mem address reg in
  output wire                     o_rami,         // ram data in
  output wire                     o_ramo,         // ram data out
  output wire                     o_instrregi,    // instruction reg in
  output wire                     o_instrrego,    // instruction reg out
  output wire                     o_aregi,        // A reg in
  output wire                     o_arego,        // A reg out
  output wire                     o_aluo,         // ALU out
  output wire                     o_alusub,       // ALU Subtract
  output wire                     o_alulatchf,    // ALU Latch Flags
  output wire                     o_bregi,        // B Reg in
  output wire                     o_oregi,        // Output Reg in
  output wire                     o_programcnten, // Program Counter Enable (increment)
  output wire                     o_programcnto,  // Program Counter Out
  output wire                     o_jump          // Jump
);

  // pnemonics for control words
  localparam HLT_ADDR = 16;
  localparam ADV_ADDR = 15;
  localparam MI_ADDR  = 14;
  localparam RI_ADDR  = 13;
  localparam RO_ADDR  = 12;
  localparam IO_ADDR  = 11;
  localparam II_ADDR  = 10;
  localparam AI_ADDR  = 9;
  localparam AO_ADDR  = 8;
  localparam EO_ADDR  = 7;
  localparam SU_ADDR  = 6;
  localparam EL_ADDR  = 5;
  localparam BI_ADDR  = 4;
  localparam OI_ADDR  = 3;
  localparam CE_ADDR  = 2;
  localparam CO_ADDR  = 1;
  localparam J_ADDR   = 0;

  localparam [CONTROL_WORD_WIDTH-1:0] c_HLT = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << HLT_ADDR; // halt
  localparam [CONTROL_WORD_WIDTH-1:0] c_ADV = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << ADV_ADDR; // advance instruction counter to next instruction
  localparam [CONTROL_WORD_WIDTH-1:0] c_MI  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << MI_ADDR;  // mem address reg in
  localparam [CONTROL_WORD_WIDTH-1:0] c_RI  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << RI_ADDR;  // ram data in
  localparam [CONTROL_WORD_WIDTH-1:0] c_RO  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << RO_ADDR;  // ram data out
  localparam [CONTROL_WORD_WIDTH-1:0] c_IO  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << IO_ADDR;  // instruction reg in
  localparam [CONTROL_WORD_WIDTH-1:0] c_II  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << II_ADDR;  // instruction reg out
  localparam [CONTROL_WORD_WIDTH-1:0] c_AI  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << AI_ADDR;  // A reg in
  localparam [CONTROL_WORD_WIDTH-1:0] c_AO  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << AO_ADDR;  // A reg out
  localparam [CONTROL_WORD_WIDTH-1:0] c_EO  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << EO_ADDR;  // ALU out
  localparam [CONTROL_WORD_WIDTH-1:0] c_SU  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << SU_ADDR;  // ALU Subtract
  localparam [CONTROL_WORD_WIDTH-1:0] c_EL  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << EL_ADDR;  // ALU Latch Flags
  localparam [CONTROL_WORD_WIDTH-1:0] c_BI  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << BI_ADDR;  // B Reg in
  localparam [CONTROL_WORD_WIDTH-1:0] c_OI  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << OI_ADDR;  // Output Reg in
  localparam [CONTROL_WORD_WIDTH-1:0] c_CE  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << CE_ADDR;  // Program Counter Enable (increment)
  localparam [CONTROL_WORD_WIDTH-1:0] c_CO  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << CO_ADDR;  // Program Counter Out
  localparam [CONTROL_WORD_WIDTH-1:0] c_J   = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << J_ADDR;   // Jump

  wire   [CONTROL_WORD_WIDTH-1:0] control_word;

  assign o_halt         = control_word[HLT_ADDR];
  assign o_adv          = control_word[ADV_ADDR];
  assign o_memaddri     = control_word[MI_ADDR];
  assign o_rami         = control_word[RI_ADDR];
  assign o_ramo         = control_word[RO_ADDR];
  assign o_instrrego    = control_word[IO_ADDR];
  assign o_instrregi    = control_word[II_ADDR];
  assign o_aregi        = control_word[AI_ADDR];
  assign o_arego        = control_word[AO_ADDR];
  assign o_aluo         = control_word[EO_ADDR];
  assign o_alusub       = control_word[SU_ADDR];
  assign o_alulatchf    = control_word[EL_ADDR];
  assign o_bregi        = control_word[BI_ADDR];
  assign o_oregi        = control_word[OI_ADDR];
  assign o_programcnten = control_word[CE_ADDR];
  assign o_programcnto  = control_word[CO_ADDR];
  assign o_jump         = control_word[J_ADDR];

  assign control_word = // fetch, put prgm cntr in mem addr, fetch instruction, advance PC. All instructions start like this
                 i_step == 'h0 ? c_MI | c_CO        :
                 i_step == 'h1 ? c_RO | c_II | c_CE :
                // i_instruction == 'h0 ? // unimplemented - defaults at bottom to NOP
                   i_instruction == 'h1 ? // LDA - put data in RAM addr in A
                     i_step == 'h2      ? c_IO | c_MI        :
                     i_step == 'h3      ? c_RO | c_AI        :
                     c_ADV :
                    i_instruction == 'h2 ? // ADD - add data from RAM addr to A
                      i_step == 'h2      ? c_IO | c_MI        :
                      i_step == 'h3      ? c_RO | c_BI        :
                      i_step == 'h4      ? c_EO | c_AI | c_EL :
                      c_ADV :
                    i_instruction == 'h3 ? // SUBTRACT - subtract data from RAM addr to A
                      i_step == 'h2      ? c_IO | c_MI        :
                      i_step == 'h3      ? c_RO | c_BI        :
                      i_step == 'h4      ? c_EO | c_SU | c_AI | c_EL :
                      c_ADV :
                    i_instruction == 'h4 ? // LDI - load an immediate 4 bit value to A
                      i_step == 'h2      ? c_IO | c_AI        :
                      c_ADV :
                    i_instruction == 'h5 ? // ADDI - add an immediate 4 bit value to A
                      i_step == 'h2      ? c_IO | c_BI        :
                      i_step == 'h3      ? c_EO | c_AI | c_EL :
                      c_ADV :
                    i_instruction == 'h6 ? // SUBTRACTI - subtract an immediate 4 bit value from A
                      i_step == 'h2      ? c_IO | c_BI        :
                      i_step == 'h3      ? c_EO | c_SU | c_AI | c_EL :
                      c_ADV :
                    i_instruction == 'h7 ? // STA - store A in RAM
                      i_step == 'h2      ? c_IO | c_MI :
                      i_step == 'h3      ? c_AO | c_RI :
                      c_ADV :
                    i_instruction == 'h8 ? // JMP - jump to ADDR
                      i_step == 'h2      ? c_IO | c_J  :
                      c_ADV :
                    i_instruction == 'h9 ? // JIZ - jump to ADDR if last ALU op was 0
                      i_step == 'h2      ? i_zero  ? (c_IO | c_J) : c_ADV :
                      c_ADV :
                    i_instruction == 'ha ? // JIC - jump to ADDR if last ALU op carried
                      i_step == 'h2      ? i_carry ? (c_IO | c_J) : c_ADV :
                      c_ADV :
                    i_instruction == 'hb ? // JIO - jump to ADDR if last ALU op was odd
                      i_step == 'h2      ? i_odd   ? (c_IO | c_J) : c_ADV :
                      c_ADV :
                 // i_instruction == 'hc ? // unimplement - defaults at bottom to NOP
                 // i_instruction == 'hd ? // unimplement - defaults at bottom to NOP
                    i_instruction == 'he ? // OUT - copy Areg to out reg
                      i_step == 'h2      ? c_AO | c_OI :
                      c_ADV :
                    i_instruction == 'hf ? // HALT PROGRAM
                      c_HLT :
                    c_ADV;                 // NOP - do nothing and just advance counter

endmodule

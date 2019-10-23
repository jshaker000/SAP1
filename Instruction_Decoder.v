// Como_breginato_instrregnal net to deo_programcntode isntructions
// May be easier to load fo_ramom a HEX file but it'll be vo_aluo_ramilog for now
// I thoguht it was easiest to assign everything to "control word" and then
// break out control word to where it needed to go for each output

module Instruction_Decoder (
  i_instruction,
  i_step,
  i_zero,
  i_carry,
  i_odd,
  o_halt,
  o_adv,
  o_memaddri,
  o_rami,
  o_ramo,
  o_instrregi,
  o_instrrego,
  o_aregi,
  o_arego,
  o_aluo,
  o_alusub,
  o_alulatchf,
  o_bregi,
  o_oregi,
  o_programcnten,
  o_programcnto,
  o_jump
);
  parameter  INSTRUCTION_WIDTH  = 4;
  parameter  INSTRUCTION_STEPS  = 8;
  parameter  CONTROL_WORD_WIDTH = 17;
  localparam STEP_WIDTH         = $clog2(INSTRUCTION_STEPS);

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

  wire [CONTROL_WORD_WIDTH-1:0] c_HLT = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << HLT_ADDR; // halt
  wire [CONTROL_WORD_WIDTH-1:0] c_ADV = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << ADV_ADDR; // advance instruction counter to next instruction
  wire [CONTROL_WORD_WIDTH-1:0] c_MI  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << MI_ADDR;  // mem address reg in
  wire [CONTROL_WORD_WIDTH-1:0] c_RI  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << RI_ADDR;  // ram data in
  wire [CONTROL_WORD_WIDTH-1:0] c_RO  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << RO_ADDR;  // ram data out
  wire [CONTROL_WORD_WIDTH-1:0] c_IO  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << IO_ADDR;  // instruction reg in
  wire [CONTROL_WORD_WIDTH-1:0] c_II  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << II_ADDR;  // instruction reg out
  wire [CONTROL_WORD_WIDTH-1:0] c_AI  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << AI_ADDR;  // A reg in
  wire [CONTROL_WORD_WIDTH-1:0] c_AO  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << AO_ADDR;  // A reg out
  wire [CONTROL_WORD_WIDTH-1:0] c_EO  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << EO_ADDR;  // ALU out
  wire [CONTROL_WORD_WIDTH-1:0] c_SU  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << SU_ADDR;  // ALU Subtract
  wire [CONTROL_WORD_WIDTH-1:0] c_EL  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << EL_ADDR;  // ALU Latch Flags
  wire [CONTROL_WORD_WIDTH-1:0] c_BI  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << BI_ADDR;  // B Reg in
  wire [CONTROL_WORD_WIDTH-1:0] c_OI  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << OI_ADDR;  // Output Reg in
  wire [CONTROL_WORD_WIDTH-1:0] c_CE  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << CE_ADDR;  // Program Counter Enable (increment)
  wire [CONTROL_WORD_WIDTH-1:0] c_CO  = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << CO_ADDR;  // Program Counter Out
  wire [CONTROL_WORD_WIDTH-1:0] c_J   = {{CONTROL_WORD_WIDTH-1{1'b0}},1'b1} << J_ADDR;   // Jump

  input   [INSTRUCTION_WIDTH-1:0] i_instruction;
  input          [STEP_WIDTH-1:0] i_step;
  input                           i_zero;
  input                           i_carry;
  input                           i_odd;

  output wire                     o_halt;         // halt
  output wire                     o_adv;          // advance instruction counter to next instruction
  output wire                     o_memaddri;     // mem address reg in
  output wire                     o_rami;         // ram data in
  output wire                     o_ramo;         // ram data out
  output wire                     o_instrregi;    // instruction reg in
  output wire                     o_instrrego;    // instruction reg out
  output wire                     o_aregi;        // A reg in
  output wire                     o_arego;        // A reg out
  output wire                     o_aluo;         // ALU out
  output wire                     o_alusub;       // ALU Subtract
  output wire                     o_alulatchf;    // ALU Latch Flags
  output wire                     o_bregi;        // B Reg in
  output wire                     o_oregi;        // Output Reg in
  output wire                     o_programcnten; // Program Counter Enable (increment)
  output wire                     o_programcnto;  // Program Counter Out
  output wire                     o_jump;         // Jump

  reg  [CONTROL_WORD_WIDTH-1:0] control_word;

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

  always @(*) begin
    case (i_instruction)
      'h1 : // LDA
        case (i_step)
          'h0    : control_word = c_MI | c_CO;
          'h1    : control_word = c_RO | c_II | c_CE;
          'h2    : control_word = c_IO | c_MI;
          'h3    : control_word = c_RO | c_AI;
          default: control_word = c_ADV;
        endcase
      'h2    : // ADD
        case (i_step)
          'h0    : control_word = c_MI | c_CO;
          'h1    : control_word = c_RO | c_II | c_CE;
          'h2    : control_word = c_IO | c_MI;
          'h3    : control_word = c_RO | c_BI;
          'h4    : control_word = c_EO | c_AI | c_EL;
          default: control_word = c_ADV;
        endcase
      'h3    : // SUBTRACT
        case (i_step)
          'h0    : control_word = c_MI | c_CO;
          'h1    : control_word = c_RO | c_II | c_CE;
          'h2    : control_word = c_IO | c_MI;
          'h3    : control_word = c_RO | c_BI;
          'h4    : control_word = c_EO | c_AI | c_SU | c_EL;
          default: control_word = c_ADV;
        endcase
      'h4    : // LDI
        case (i_step)
          'h0    : control_word = c_MI | c_CO;
          'h1    : control_word = c_RO | c_II | c_CE;
          'h2    : control_word = c_IO | c_AI;
          default: control_word = c_ADV;
        endcase
      'h5    : // ADDI
        case (i_step)
          'h0    : control_word = c_MI | c_CO;
          'h1    : control_word = c_RO | c_II | c_CE;
          'h2    : control_word = c_IO | c_BI;
          'h3    : control_word = c_EO | c_AI | c_EL;
          default: control_word = c_ADV;
        endcase
      'h6    : // SUBTRACTI
        case (i_step)
          'h0    : control_word = c_MI | c_CO;
          'h1    : control_word = c_RO | c_II | c_CE;
          'h2    : control_word = c_IO | c_BI;
          'h3    : control_word = c_EO | c_AI | c_SU | c_EL;
          default: control_word = c_ADV;
        endcase
      'h7    : // STA
        case (i_step)
          'h0    : control_word = c_MI | c_CO;
          'h1    : control_word = c_RO | c_II | c_CE;
          'h2    : control_word = c_IO | c_MI;
          'h3    : control_word = c_AO | c_RI;
          default: control_word = c_ADV;
        endcase
      'h8    : // JMP
        case (i_step)
          'h0    : control_word = c_MI | c_CO;
          'h1    : control_word = c_RO | c_II | c_CE;
          'h2    : control_word = c_IO | c_J;
          default: control_word = c_ADV;
        endcase
      'h9    : // JIZ
        case (i_step)
          'h0    : control_word = c_MI | c_CO;
          'h1    : control_word = c_RO | c_II | c_CE;
          'h2    : control_word = i_zero ? (c_IO | c_J) : c_ADV;
          default: control_word = c_ADV;
        endcase
      'ha    : // JIC
        case (i_step)
          'h0    : control_word = c_MI | c_CO;
          'h1    : control_word = c_RO | c_II | c_CE;
          'h2    : control_word = i_carry ? (c_IO | c_J) : c_ADV;
          default: control_word = c_ADV;
        endcase
      'hb    : // JIO
        case (i_step)
          'h0    : control_word = c_MI | c_CO;
          'h1    : control_word = c_RO | c_II | c_CE;
          'h2    : control_word = i_odd ? (c_IO | c_J)   : c_ADV;
          default: control_word = c_ADV;
        endcase
      'he    : // OUT
        case (i_step)
          'h0    : control_word = c_MI | c_CO;
          'h1    : control_word = c_RO | c_II | c_CE;
          'h2    : control_word = c_AO | c_OI;
          default: control_word = c_ADV;
        endcase
      'hf    : // HLT
        case (i_step)
          default: control_word = c_HLT;
        endcase
      default:     // NOP - in this case 'h0, 'hc, 'hd,  You can add instructions to c,d to make nop just 0 or you could program over 0
                   // too to elimate NOP entirely
        case (i_step)
          'h0    : control_word = c_MI | c_CO;
          'h1    : control_word = c_RO | c_II | c_CE;
          default: control_word = c_ADV;
        endcase
    endcase
  end

endmodule

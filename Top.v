`default_nettype none

module Top #(
  parameter BUS_WIDTH   = 8,
  parameter A_REG_WIDTH = 8,
  parameter B_REG_WIDTH = 8,
  parameter ALU_WIDTH   = 8,
  parameter OUT_WIDTH   = 8,

  parameter INSTRUCTION_REGISTER_WIDTH     = 8,
  parameter INSTRUCTION_REGISTER_OUT_WIDTH = 4,

  parameter PROGRAM_COUNTER_WIDTH          = 4,

  parameter RAM_DEPTH         = 2**PROGRAM_COUNTER_WIDTH,
  parameter RAM_WIDTH         = 8,

  parameter INSTRUCTION_WIDTH  = 4,
  parameter INSTRUCTION_STEPS  = 8,

  parameter FILE               = "ram.hex",

  localparam ADDRESS_WIDTH             = $clog2(RAM_DEPTH),
  localparam INSTRUCTION_COUNTER_WIDTH = $clog2(INSTRUCTION_STEPS)
)(
  input wire clk,
  output wire [OUT_WIDTH-1:0] out_data
);

  `include "instructions.vi"


/*------------------BEGIN INTERCONNECTS----------------------------------*/
  // clock enable
  wire  clk_en;

  // Instruction Decoder
  wire [CONTROL_WORD_WIDTH-1:0] control_word;

  // bus
  wire                         [BUS_WIDTH-1:0] bus_out;

  // program counter
  wire             [PROGRAM_COUNTER_WIDTH-1:0] program_counter;

  // instruction counter
  wire         [INSTRUCTION_COUNTER_WIDTH-1:0] instruction_counter;

  // instruction register
  wire        [INSTRUCTION_REGISTER_WIDTH-1:0] instruction_reg;
  wire    [INSTRUCTION_REGISTER_OUT_WIDTH-1:0] instruction_reg_to_bus = instruction_reg[INSTRUCTION_REGISTER_OUT_WIDTH-1:0];
  wire                 [INSTRUCTION_WIDTH-1:0] instruction            = instruction_reg[INSTRUCTION_REGISTER_WIDTH-1 -: INSTRUCTION_WIDTH];

  // memory address
  wire                     [ADDRESS_WIDTH-1:0] memory_address;

  // ram data
  wire                         [RAM_WIDTH-1:0] ram_data;

  // a register
  wire                       [A_REG_WIDTH-1:0] a_reg;

  // b register
  wire                       [B_REG_WIDTH-1:0] b_reg;

  // alu out
  wire                         [ALU_WIDTH-1:0] alu_data;
  wire                                         zero;
  wire                                         carry;
  wire                                         odd;

/*-------------------END INTERCONNECTS-----------------------------------*/

  Clock_Enable inst_Clock_Enable(
    .clk   (clk),
    .clk_en(clk_en)
  );

  Instruction_Decoder #(
    .INSTRUCTION_WIDTH(INSTRUCTION_WIDTH),
    .INSTRUCTION_STEPS(INSTRUCTION_STEPS)
  ) inst_Instruction_Decoder(
      .i_instruction (instruction),
      .i_step        (instruction_counter),
      .i_zero        (zero),
      .i_carry       (carry),
      .i_odd         (odd),
      .o_control_word(control_word)
  );

  Bus #(
    .BUS_WIDTH                (BUS_WIDTH),
    .A_REG_OUT_WIDTH          (A_REG_WIDTH),
    .B_REG_OUT_WIDTH          (B_REG_WIDTH),
    .ALU_OUT_WIDTH            (ALU_WIDTH),
    .RAM_OUT_WIDTH            (RAM_WIDTH),
    .INSTRUCTION_REG_OUT_WIDTH(INSTRUCTION_REGISTER_OUT_WIDTH),
    .PROGRAM_COUNTER_OUT_WIDTH(PROGRAM_COUNTER_WIDTH)
  ) inst_Bus (
    .i_a_reg_out           (control_word[AO_POS]),
    .i_a_reg_data          (a_reg),
    .i_b_reg_out           (1'b0),
    .i_b_reg_data          (b_reg),
    .i_alu_out             (control_word[EO_POS]),
    .i_alu_data            (alu_data),
    .i_ram_out             (control_word[RO_POS]),
    .i_ram_data            (ram_data),
    .i_instruction_reg_out (control_word[IO_POS]),
    .i_instruction_reg_data(instruction_reg_to_bus),
    .i_program_counter_out (control_word[CO_POS]),
    .i_program_counter_data(program_counter),
    .o_bus_out             (bus_out)
  );

  Program_Counter #(
    .WIDTH(PROGRAM_COUNTER_WIDTH)
  ) inst_Program_Counter (
    .clk            (clk),
    .clk_en         (clk_en),
    .i_counter_enable(control_word[CE_POS]),
    .i_halt          (control_word[HLT_POS]),
    .i_load_enable   (control_word[J_POS]),
    .i_load_data     (bus_out[PROGRAM_COUNTER_WIDTH-1:0]),
    .o_data          (program_counter)
  );

  Instruction_Counter #(
    .INSTRUCTION_STEPS(INSTRUCTION_STEPS)
  ) inst_Instruction_Counter (
    .clk    (clk),
    .clk_en (clk_en),
    .i_halt (control_word[HLT_POS]),
    .i_adv  (control_word[ADV_POS]),
    .o_data (instruction_counter)
  );

  Register #(
    .WIDTH(INSTRUCTION_REGISTER_WIDTH)
  ) inst_Register_Instruction (
    .clk          (clk),
    .clk_en       (clk_en),
    .i_load_enable(control_word[II_POS]),
    .i_load_data  (bus_out[INSTRUCTION_REGISTER_WIDTH-1:0]),
    .o_data       (instruction_reg)
  );

  Register #(
    .WIDTH(ADDRESS_WIDTH)
  ) inst_Register_Memory_Address (
    .clk          (clk),
    .clk_en       (clk_en),
    .i_load_enable(control_word[MI_POS]),
    .i_load_data  (bus_out[ADDRESS_WIDTH-1:0]),
    .o_data       (memory_address)
  );

  Ram #(
    .RAM_DEPTH(RAM_DEPTH),
    .WIDTH    (RAM_WIDTH),
    .FILE     (FILE)
  ) inst_Ram (
    .clk          (clk),
    .clk_en       (clk_en),
    .i_address    (memory_address),
    .i_load_enable(control_word[RI_POS]),
    .i_load_data  (bus_out[RAM_WIDTH-1:0]),
    .o_data       (ram_data)
  );

  Register #(
    .WIDTH(A_REG_WIDTH)
  ) inst_Register_A (
    .clk          (clk),
    .clk_en       (clk_en),
    .i_load_enable(control_word[AI_POS]),
    .i_load_data  (bus_out[A_REG_WIDTH-1:0]),
    .o_data       (a_reg)
  );

  Register #(
    .WIDTH(B_REG_WIDTH)
  ) inst_Register_B (
    .clk          (clk),
    .clk_en       (clk_en),
    .i_load_enable(control_word[BI_POS]),
    .i_load_data  (bus_out[B_REG_WIDTH-1:0]),
    .o_data       (b_reg)
  );

  ALU #(
    .WIDTH(ALU_WIDTH)
  ) inst_ALU (
    .clk          (clk),
    .clk_en       (clk_en),
    .i_latch_flags(control_word[EL_POS]),
    .i_sub        (control_word[SU_POS]),
    .i_a          (a_reg),
    .i_b          (b_reg),
    .o_zero       (zero),
    .o_carry      (carry),
    .o_odd        (odd),
    .o_data       (alu_data)
  );

  Out #(
    .WIDTH(OUT_WIDTH)
  ) inst_Out (
    .clk          (clk),
    .clk_en       (clk_en),
    .i_load_enable(control_word[OI_POS]),
    .i_load_data  (bus_out[OUT_WIDTH-1:0]),
    .o_data       (out_data)
  );

  // Functions to access internal signals from verilator
  `ifdef verilator
    function get_halt;
      // verilator public
      get_halt = control_word[HLT_POS];
    endfunction
    function get_adv;
      // verilator public
      get_adv = control_word[ADV_POS];
    endfunction
    function get_memaddri;
      // verilator public
      get_memaddri = control_word[MI_POS];
    endfunction
    function get_rami;
      // verilator public
      get_rami = control_word[RI_POS];
    endfunction
    function get_ramo;
      // verilator public
      get_ramo = control_word[RO_POS];
    endfunction
    function get_instrregi;
      // verilator public
      get_instrregi = control_word[II_POS];
    endfunction
    function get_instrrego;
      // verilator public
      get_instrrego = control_word[IO_POS];
    endfunction
    function get_aregi;
      // verilator public
      get_aregi = control_word[AI_POS];
    endfunction
    function get_arego;
      // verilator public
      get_arego = control_word[AO_POS];
    endfunction
    function get_aluo;
      // verilator public
      get_aluo = control_word[EO_POS];
    endfunction
    function get_alusub;
      // verilator public
      get_alusub = control_word[SU_POS];
    endfunction
    function get_alulatchf;
      // verilator public
      get_alulatchf = control_word[EL_POS];
    endfunction
    function get_bregi;
      // verilator public
      get_bregi = control_word[BI_POS];
    endfunction
    function get_oregi;
      // verilator public
      get_oregi = control_word[OI_POS];
    endfunction
    function get_programcnten;
      // verilator public
      get_programcnten = control_word[CE_POS];
    endfunction
    function get_programcnto;
      // verilator public
      get_programcnto = control_word[CO_POS];
    endfunction
    function get_jump;
      // verilator public
      get_jump = control_word[J_POS];
    endfunction

    function [BUS_WIDTH-1:0] get_bus_out;
    // verilator public
      get_bus_out = bus_out;
    endfunction

    function [PROGRAM_COUNTER_WIDTH-1:0] get_program_counter;
    // verilator public
      get_program_counter = program_counter;
    endfunction

    function [INSTRUCTION_COUNTER_WIDTH-1:0] get_instruction_counter;
    // verilator public
      get_instruction_counter = instruction_counter;
    endfunction

    function [INSTRUCTION_REGISTER_WIDTH-1:0] get_instruction_reg;
    // verilator public
      get_instruction_reg = instruction_reg;
    endfunction

    function [ADDRESS_WIDTH-1:0] get_memory_address;
    // verilator public
      get_memory_address = memory_address;
    endfunction

    function [RAM_WIDTH-1:0] get_ram_data;
    // verilator public
      get_ram_data = ram_data;
    endfunction

    function [A_REG_WIDTH-1:0] get_a_reg;
    // verilator public
      get_a_reg = a_reg;
    endfunction

    function [B_REG_WIDTH-1:0] get_b_reg;
    // verilator public
      get_b_reg = b_reg;
    endfunction

    function [ALU_WIDTH-1:0] get_alu_data;
    // verilator public
      get_alu_data = alu_data;
    endfunction

    function get_zero;
    // verilator public
      get_zero = zero;
    endfunction
    function get_carry;
    // verilator public
      get_carry = carry;
    endfunction
    function get_odd;
    // verilator public
      get_odd = odd;
    endfunction

    function [OUT_WIDTH-1:0] get_out_data;
    // verilator public
      get_out_data = out_data;
    endfunction

  `endif

endmodule

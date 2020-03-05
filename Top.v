module Top(
  mclk
);

  parameter BUS_WIDTH   = 8;
  parameter A_REG_WIDTH = 8;
  parameter B_REG_WIDTH = 8;
  parameter ALU_WIDTH   = 8;
  parameter OUT_WIDTH   = 8;

  parameter INSTRUCTION_REGISTER_WIDTH     = 8;
  parameter INSTRUCTION_REGISTER_OUT_WIDTH = 4;

  parameter PROGRAM_COUNTER_WIDTH          = 4;

  parameter RAM_DEPTH         = 16;
  parameter RAM_WIDTH         = 8;

  parameter INSTRUCTION_WIDTH  = 4;
  parameter INSTRUCTION_STEPS  = 8;
  parameter CONTROL_WORD_WIDTH = 17;

  localparam ADDRESS_WIDTH             = $clog2(RAM_DEPTH);
  localparam INSTRUCTION_COUNTER_WIDTH = $clog2(INSTRUCTION_STEPS);

/*--------------BEGIN IO-------------------------------------------------*/
  input mclk;
/*---------------END IO--------------------------------------------------*/

/*------------------BEGIN INTERCONNECTS----------------------------------*/
  // clock enable
  wire  mclk_en;

  // Instruction Decoder
  wire halt;         // halt
  wire adv;          // advance instruction counter to next instruction
  wire memaddri;     // mem address reg in
  wire rami;         // ram data in
  wire ramo;         // ram data out
  wire instrregi;    // instruction reg in
  wire instrrego;    // instruction reg out
  wire aregi;        // A reg in
  wire arego;        // A reg out
  wire aluo;         // ALU out
  wire alusub;       // ALU Subtract
  wire alulatchf;    // ALU Latch Flags
  wire bregi;        // B Reg in
  wire oregi;        // Output Reg in
  wire programcnten; // Program Counter Enable (increment)
  wire programcnto;  // Program Counter Out
  wire jump;         // Jump

  // bus
  wire                         [BUS_WIDTH-1:0] bus_out;

  // program counter
  wire             [PROGRAM_COUNTER_WIDTH-1:0] program_counter;

  // instruction counter
  wire         [INSTRUCTION_COUNTER_WIDTH-1:0] instruction_counter;

  // instruction register
  wire        [INSTRUCTION_REGISTER_WIDTH-1:0] instruction_reg;
  wire    [INSTRUCTION_REGISTER_OUT_WIDTH-1:0] instruction_reg_to_bus = instruction_reg[INSTRUCTION_REGISTER_OUT_WIDTH-1:0];
  wire                 [INSTRUCTION_WIDTH-1:0] instruction            = instruction_reg[INSTRUCTION_REGISTER_WIDTH-1:INSTRUCTION_WIDTH];

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

  // out data
  wire                         [OUT_WIDTH-1:0] out_data;
/*-------------------END INTERCONNECTS-----------------------------------*/

  Clock_Enable inst_Clock_Enable(
    .mclk   (mclk),
    .mclk_en(mclk_en)
  );

  Instruction_Decoder #(
    .INSTRUCTION_WIDTH(INSTRUCTION_WIDTH),
    .INSTRUCTION_STEPS(INSTRUCTION_STEPS),
    .CONTROL_WORD_WIDTH(CONTROL_WORD_WIDTH)
  ) inst_Instruction_Decoder(
      .i_instruction (instruction),
      .i_step        (instruction_counter),
      .i_zero        (zero),
      .i_carry       (carry),
      .i_odd         (odd),
      .o_halt        (halt),
      .o_adv         (adv),
      .o_memaddri    (memaddri),
      .o_rami        (rami),
      .o_ramo        (ramo),
      .o_instrregi   (instrregi),
      .o_instrrego   (instrrego),
      .o_aregi       (aregi),
      .o_arego       (arego),
      .o_aluo        (aluo),
      .o_alusub      (alusub),
      .o_alulatchf   (alulatchf),
      .o_bregi       (bregi),
      .o_oregi       (oregi),
      .o_programcnten(programcnten),
      .o_programcnto (programcnto),
      .o_jump        (jump)
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
    .i_a_reg_out           (arego),
    .i_a_reg_data          (a_reg),
    .i_b_reg_out           (1'b0),
    .i_b_reg_data          (b_reg),
    .i_alu_out             (aluo),
    .i_alu_data            (alu_data),
    .i_ram_out             (ramo),
    .i_ram_data            (ram_data),
    .i_instruction_reg_out (instrrego),
    .i_instruction_reg_data(instruction_reg_to_bus),
    .i_program_counter_out (programcnto),
    .i_program_counter_data(program_counter),
    .o_bus_out             (bus_out)
  );

  Program_Counter #(
    .WIDTH(PROGRAM_COUNTER_WIDTH)
  ) inst_Program_Counter (
    .mclk            (mclk),
    .mclk_en         (mclk_en),
    .i_counter_enable(programcnten),
    .i_halt          (halt),
    .i_load_enable   (jump),
    .i_load_data     (bus_out[PROGRAM_COUNTER_WIDTH-1:0]),
    .o_data          (program_counter)
  );

  Instruction_Counter #(
    .INSTRUCTION_STEPS(INSTRUCTION_STEPS)
  ) inst_Instruction_Counter (
    .mclk   (mclk),
    .mclk_en(mclk_en),
    .i_halt (halt),
    .i_adv  (adv),
    .o_data (instruction_counter)
  );

  Register #(
    .WIDTH(INSTRUCTION_REGISTER_WIDTH)
  ) inst_Register_Instruction (
    .mclk         (mclk),
    .mclk_en      (mclk_en),
    .i_load_enable(instrregi),
    .i_load_data  (bus_out[INSTRUCTION_REGISTER_WIDTH-1:0]),
    .o_data       (instruction_reg)
  );

  Register #(
    .WIDTH(ADDRESS_WIDTH)
  ) inst_Register_Memory_Address (
    .mclk         (mclk),
    .mclk_en      (mclk_en),
    .i_load_enable(memaddri),
    .i_load_data  (bus_out[ADDRESS_WIDTH-1:0]),
    .o_data       (memory_address)
  );

  Ram #(
    .RAM_DEPTH(RAM_DEPTH),
    .WIDTH    (RAM_WIDTH)
  ) inst_Ram (
    .mclk         (mclk),
    .mclk_en      (mclk_en),
    .i_address    (memory_address),
    .i_load_enable(rami),
    .i_load_data  (bus_out[RAM_WIDTH-1:0]),
    .o_data       (ram_data)
  );

  Register #(
    .WIDTH(A_REG_WIDTH)
  ) inst_Register_A (
    .mclk         (mclk),
    .mclk_en      (mclk_en),
    .i_load_enable(aregi),
    .i_load_data  (bus_out[A_REG_WIDTH-1:0]),
    .o_data       (a_reg)
  );

  Register #(
    .WIDTH(B_REG_WIDTH)
  ) inst_Register_B (
    .mclk         (mclk),
    .mclk_en      (mclk_en),
    .i_load_enable(bregi),
    .i_load_data  (bus_out[B_REG_WIDTH-1:0]),
    .o_data       (b_reg)
  );

  ALU #(
    .WIDTH(ALU_WIDTH)
  ) inst_ALU (
    .mclk         (mclk),
    .mclk_en      (mclk_en),
    .i_latch_flags(alulatchf),
    .i_sub        (alusub),
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
    .mclk         (mclk),
    .mclk_en      (mclk_en),
    .i_load_enable(oregi),
    .i_load_data  (bus_out[OUT_WIDTH-1:0]),
    .o_data       (out_data)
  );

  // Functions to access internal signals from verilator
  `ifdef verilator
    function get_halt;
      // verilator public
      get_halt = halt;
    endfunction
    function get_adv;
      // verilator public
      get_adv = adv;
    endfunction
    function get_memaddri;
      // verilator public
      get_memaddri = memaddri;
    endfunction
    function get_rami;
      // verilator public
      get_rami = rami;
    endfunction
    function get_ramo;
      // verilator public
      get_ramo = ramo;
    endfunction
    function get_instrregi;
      // verilator public
      get_instrregi = instrregi;
    endfunction
    function get_instrrego;
      // verilator public
      get_instrrego = instrrego;
    endfunction
    function get_aregi;
      // verilator public
      get_aregi = aregi;
    endfunction
    function get_arego;
      // verilator public
      get_arego = arego;
    endfunction
    function get_aluo;
      // verilator public
      get_aluo = aluo;
    endfunction
    function get_alusub;
      // verilator public
      get_alusub = alusub;
    endfunction
    function get_alulatchf;
      // verilator public
      get_alulatchf = alulatchf;
    endfunction
    function get_bregi;
      // verilator public
      get_bregi = bregi;
    endfunction
    function get_oregi;
      // verilator public
      get_oregi = oregi;
    endfunction
    function get_programcnten;
      // verilator public
      get_programcnten = programcnten;
    endfunction
    function get_programcnto;
      // verilator public
      get_programcnto = programcnto;
    endfunction
    function get_jump;
      // verilator public
      get_jump = jump;
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

// My verilog simulator does not do tristate logic
// Instead, we will send all data to the bus and AND it with a MASK of its valid
// The bus will then OR reduce and output. At any given time, only one valid
// should be high anyway so this works will

`default_nettype none

module Bus #(
  parameter BUS_WIDTH                 = 8,
  parameter A_REG_OUT_WIDTH           = 8,
  parameter B_REG_OUT_WIDTH           = 8,
  parameter ALU_OUT_WIDTH             = 8,
  parameter RAM_OUT_WIDTH             = 8,
  parameter INSTRUCTION_REG_OUT_WIDTH = 4,
  parameter PROGRAM_COUNTER_OUT_WIDTH = 4
)(
  input wire i_a_reg_out,
  input wire i_b_reg_out,
  input wire i_alu_out,
  input wire i_ram_out,
  input wire i_instruction_reg_out,
  input wire i_program_counter_out,

  input wire           [A_REG_OUT_WIDTH-1:0] i_a_reg_data,
  input wire           [A_REG_OUT_WIDTH-1:0] i_b_reg_data,
  input wire             [ALU_OUT_WIDTH-1:0] i_alu_data,
  input wire             [RAM_OUT_WIDTH-1:0] i_ram_data,
  input wire [INSTRUCTION_REG_OUT_WIDTH-1:0] i_instruction_reg_data,
  input wire [PROGRAM_COUNTER_OUT_WIDTH-1:0] i_program_counter_data,

  output wire                [BUS_WIDTH-1:0] o_bus_out
);

  //left fill with 0's if need be, and mask with data with valids
  wire [BUS_WIDTH-1:0] a_reg_masked           =  {{BUS_WIDTH-A_REG_OUT_WIDTH{1'b0}},          i_a_reg_data}
                                                & {BUS_WIDTH{i_a_reg_out}};
  wire [BUS_WIDTH-1:0] b_reg_masked           =  {{BUS_WIDTH-B_REG_OUT_WIDTH{1'b0}},          i_b_reg_data}
                                                & {BUS_WIDTH{i_b_reg_out}};
  wire [BUS_WIDTH-1:0] alu_masked             =  {{BUS_WIDTH-ALU_OUT_WIDTH{1'b0}},            i_alu_data}
                                                & {BUS_WIDTH{i_alu_out}};
  wire [BUS_WIDTH-1:0] ram_masked             =  {{BUS_WIDTH-RAM_OUT_WIDTH{1'b0}},            i_ram_data}
                                                & {BUS_WIDTH{i_ram_out}};
  wire [BUS_WIDTH-1:0] instruction_masked     =  {{BUS_WIDTH-INSTRUCTION_REG_OUT_WIDTH{1'b0}},i_instruction_reg_data}
                                                & {BUS_WIDTH{i_instruction_reg_out}};
  wire [BUS_WIDTH-1:0] program_counter_masked =  {{BUS_WIDTH-PROGRAM_COUNTER_OUT_WIDTH{1'b0}},i_program_counter_data}
                                                & {BUS_WIDTH{i_program_counter_out}};

  assign o_bus_out = a_reg_masked       | b_reg_masked |
                     alu_masked         | ram_masked   |
                     instruction_masked | program_counter_masked;

endmodule

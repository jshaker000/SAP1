// Simple ALU that can add or subtrack.
// Can optionally latch its flags, which can be used as inputs to the
// Instruction decoding for JIZ instructions and the like,

`default_nettype none

module ALU #(
  parameter WIDTH = 8
)(
  input  wire            clk,
  input  wire            clk_en,
  input  wire            i_latch_flags,
  input  wire            i_sub,
  input  wire [WIDTH-1:0] i_a,
  input  wire [WIDTH-1:0] i_b,

  output reg              o_zero,
  output reg              o_carry,
  output reg              o_odd,
  output wire [WIDTH-1:0] o_data
);

  initial begin
    o_zero  = 1'b0;
    o_carry = 1'b0;
    o_odd   = 1'b0;
  end

  wire           latch  = clk_en & i_latch_flags;
  wire [WIDTH:0] result = (i_sub == 1'b0) ? i_a + i_b : i_a - i_b;

  assign o_data         = result[WIDTH-1:0];

  always @(posedge clk) o_zero  <= latch ? o_data == {WIDTH{1'b0}} : o_zero;
  always @(posedge clk) o_carry <= latch ? result[WIDTH]           : o_carry;
  always @(posedge clk) o_odd   <= latch ? o_data[0]               : o_odd;

endmodule

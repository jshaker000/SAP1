module ALU(
  mclk,
  mclk_en,
  i_latch_flags,
  i_sub,
  i_a,
  i_b,
  o_zero,
  o_carry,
  o_odd,
  o_data
);

  parameter WIDTH = 8;

  input              mclk;
  input              mclk_en;
  input              i_latch_flags;
  input              i_sub;
  input  [WIDTH-1:0] i_a;
  input  [WIDTH-1:0] i_b;

  output reg         o_zero  = 0;
  output reg         o_carry = 0;
  output reg         o_odd   = 0;
  output [WIDTH-1:0] o_data;

  wire           latch  = mclk_en & i_latch_flags;
  wire [WIDTH:0] result = (i_sub == 1'b0) ? i_a + i_b : i_a - i_b;

  assign o_data         = result[WIDTH-1:0];

  always @(posedge mclk) o_zero  <= latch ? o_data == {WIDTH{1'b0}} : o_zero;
  always @(posedge mclk) o_carry <= latch ? result[WIDTH]           : o_carry;
  always @(posedge mclk) o_odd   <= latch ? o_data[0]               : o_odd;

endmodule

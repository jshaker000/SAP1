// To decode to 7 seg, will be different on every FPGA.
// For now this will be a dummy register
// You will either need a BIG lookup table, or a BIN - BCD converter or
// something

module Out(
  mclk,
  mclk_en,
  i_load_enable,
  i_load_data,
  o_data
);

  parameter WIDTH = 8;

  input                    mclk;
  input                    mclk_en;
  input                    i_load_enable;
  input        [WIDTH-1:0] i_load_data;

  output reg   [WIDTH-1:0] o_data = 0;

  wire transition = mclk_en & i_load_enable;

  always @(posedge mclk) o_data <= transition ? i_load_data : o_data;

endmodule

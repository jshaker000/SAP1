// To decode to 7 seg, will be different on every FPGA.
// For now this will be a dummy register
// You will either need a BIG lookup table, or a BIN - BCD converter or
// something

`default_nettype none

module Out #(
  parameter WIDTH = 8
)(
  input                    clk,
  input                    clk_en,
  input                    i_load_enable,
  input        [WIDTH-1:0] i_load_data,
  output reg   [WIDTH-1:0] o_data
);

  initial begin
    o_data = {WIDTH{1'b0}};
  end

  wire load = clk_en & i_load_enable;

  always @(posedge clk) o_data <= load ? i_load_data : o_data;

endmodule

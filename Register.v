`default_nettype none

module Register #(
  parameter WIDTH = 8
)(
  input wire             mclk,
  input wire             mclk_en,
  input wire             i_load_enable,
  input wire [WIDTH-1:0] i_load_data,

  output reg [WIDTH-1:0] o_data
);

  initial begin
    o_data = {WIDTH{1'b0}};
  end

  wire load = mclk_en & i_load_enable;

  always @(posedge mclk) o_data <= load ? i_load_data : o_data;

endmodule

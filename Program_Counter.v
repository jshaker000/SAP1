`default_nettype none

module Program_Counter #(
  parameter WIDTH = 4
)(
  input  wire             clk,
  input  wire             clk_en,
  input  wire             i_counter_enable,
  input  wire             i_halt,
  input  wire             i_load_enable,
  input  wire [WIDTH-1:0] i_load_data,

  output wire [WIDTH-1:0] o_data
);

  reg    [WIDTH-1:0] counter = {WIDTH{1'b0}};

  wire   [WIDTH-1:0] counter_next   = i_load_enable    ? i_load_data :
                                      i_counter_enable ? counter + {{WIDTH-1{1'b0}}, 1'b1} :
                                      counter;

  wire               update_counter = clk_en & ~i_halt;

  always @(posedge clk) counter <= update_counter ? counter_next : counter;

  assign o_data = counter;

endmodule

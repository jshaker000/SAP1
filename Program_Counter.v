module Program_Counter(
  mclk,
  mclk_en,
  i_counter_enable,
  i_halt,
  i_load_enable,
  i_load_data,
  o_data
);

  parameter WIDTH = 4;

  input              mclk;
  input              mclk_en;
  input              i_counter_enable;
  input              i_halt;
  input              i_load_enable;
  input  [WIDTH-1:0] i_load_data;

  output [WIDTH-1:0] o_data;

  reg    [WIDTH-1:0] counter = {WIDTH{1'b0}};

  wire   [WIDTH-1:0] counter_next   = i_load_enable    ? i_load_data :
                                      i_counter_enable ? counter + {{WIDTH-1{1'b0}}, 1'b1} :
                                      counter;

  wire               update_counter = mclk_en & ~i_halt;

  always @(posedge mclk) counter <= update_counter ? counter_next :
                                    counter;

  assign o_data = counter;

endmodule

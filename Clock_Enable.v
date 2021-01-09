// You can use this module to turn "CLK_ENABLE" on and off.
// You may want to do this to set a button step mode, or to just slow down
// clock by a factor of say 100 million if you are running on an FPGA
// For simulation, clock enable can always be 1

  /*
   * Example clock division
   * parameter DIV_RATIO     = 100000000;
   * localparam DIV_RATIO_M1 = DIV_RATIO -1;
   * localparam COUNT_W      = $clog2(DIV_RATIO);
   * reg [COUNT_W-1:0] clock_cnt = DIV_RATIO_M1;
   * wire next_pulse = clock_cnt == {COUNT_W{1'b0}};
   * always @(posedge clk) clock_cnt <= next_pulse ? DIV_RATIO_M1 : clock_cnt - {{COUNT_W-1{1'b0}}, 1'b1};
   * assign mcl_en = next_pulse;
  */

`default_nettype none

module Clock_Enable (
/* verilator lint_off UNUSED */
  input  wire clk,
/* verilator lint_on UNUSED */
  output wire clk_en
);

  assign clk_en = 1'b1;
endmodule

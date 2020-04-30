// You can use this module to turn "CLK_ENABLE" on and off.
// You may want to do this to set a button step mode, or to just slow down
// clock by a factor of say 100 million if you are running on an FPGA
// For simulation, clock enable can always be 1

`default_nettype none

module Clock_Enable (
/* verilator lint_off UNUSED */
  input  wire mclk,
/* verilator lint_on UNUSED */
  output wire mclk_en
);

  assign mclk_en = 1'b1;

endmodule

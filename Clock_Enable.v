// You can use this module to turn "CLK_ENABLE" on and off.
// You may want to do this to set a button step mode, or to just slow down
// clock by a factor of say 100 million if you are running on an FPGA
// For simulation, clock enable can always be 1

module Clock_Enable (
  mclk,
  mclk_en
);

/* verilator lint_off UNUSED */
  input  mclk;
/* verilator lint_on UNUSED */
  output mclk_en;

  assign mclk_en = 1'b1;

endmodule

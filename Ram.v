`default_nettype none

module Ram #(
  parameter  RAM_DEPTH  = 16,
  parameter  WIDTH      =  8,
  parameter  FILE       = "ram.hex",
  localparam ADDR_WIDTH = $clog2(RAM_DEPTH)
)(
  input  wire                  mclk,
  input  wire                  mclk_en,
  input  wire [ADDR_WIDTH-1:0] i_address,
  input  wire                  i_load_enable,
  input  wire      [WIDTH-1:0] i_load_data,
  output wire      [WIDTH-1:0] o_data
);

  reg        [WIDTH-1:0] ram [0:RAM_DEPTH-1];
  wire                   write = mclk_en & i_load_enable;

  initial begin
    $readmemh(FILE, ram);
  end

  always @(posedge mclk) if (write) ram[i_address] <= i_load_data;

  assign o_data = ram[i_address];

endmodule

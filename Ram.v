`default_nettype none

// Load ram from file, then allow Ram to be addressed for reading / writing. This is single port Ram
// (meaning that the same address is used for reading and writing) and it is NOT write through
// (meaning reading / writing simultaneously will read the old data and write the new data

module Ram #(
  parameter  RAM_DEPTH  = 16,
  parameter  WIDTH      =  8,
  parameter  FILE       = "ram.hex",
  localparam ADDR_WIDTH = $clog2(RAM_DEPTH)
)(
  input  wire                  clk,
  input  wire                  clk_en,
  input  wire [ADDR_WIDTH-1:0] i_address,
  input  wire                  i_load_enable,
  input  wire      [WIDTH-1:0] i_load_data,
  output wire      [WIDTH-1:0] o_data
);

  reg        [WIDTH-1:0] ram [0:RAM_DEPTH-1];
  wire                   write = clk_en & i_load_enable;

  initial begin
    $readmemh(FILE, ram);
  end

  always @(posedge clk) ram[i_address] <= write ? i_load_data : ram[i_address];

  assign o_data = ram[i_address];

endmodule

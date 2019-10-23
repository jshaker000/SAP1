module Ram(
  mclk,
  mclk_en,
  i_address,
  i_load_enable,
  i_load_data,
  o_data
);

  parameter  RAM_DEPTH  = 16;
  parameter  WIDTH      =  8;
  localparam ADDR_WIDTH = $clog2(RAM_DEPTH);

  input                  mclk;
  input                  mclk_en;
  input [ADDR_WIDTH-1:0] i_address;
  input                  i_load_enable;
  input      [WIDTH-1:0] i_load_data;

  output     [WIDTH-1:0] o_data;

  reg        [WIDTH-1:0] ram [0:RAM_DEPTH-1];
  wire                   write = mclk_en & i_load_enable;

  // initialize ram with a hex file
  initial begin
    $readmemh("ram.hex",ram);
  end

  // should infer as ram but need to double check
  // may need to register outputs
  always @(posedge mclk) ram[i_address] <= write ? i_load_data : ram[i_address];
  assign                        o_data   = ram[i_address];

endmodule

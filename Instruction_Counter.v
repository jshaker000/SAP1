// maintain which step of the instruction we are on

module Instruction_Counter(
  mclk,
  mclk_en,
  i_halt,
  i_adv,
  o_data
);

  parameter  INSTRUCTION_STEPS = 8;
  localparam STEP_WIDTH        = $clog2(INSTRUCTION_STEPS);

  input mclk;
  input mclk_en;
  input i_adv;
  input i_halt;

  output [STEP_WIDTH-1:0] o_data;

  reg    [STEP_WIDTH-1:0] counter = {STEP_WIDTH{1'b0}};

  wire counter_max    = (counter) == (INSTRUCTION_STEPS[STEP_WIDTH-1:0] - 'd1);
  wire update_counter = mclk_en & ~i_halt;
  wire reset_counter  = i_adv | counter_max;

  wire [STEP_WIDTH-1:0] counter_next = reset_counter ? {STEP_WIDTH{1'b0}} :
                                       counter + {{STEP_WIDTH-1{1'b0}}, 1'b1};

  always @(posedge mclk) counter <= update_counter ? counter_next :
                                    counter;
  assign o_data = counter;
endmodule

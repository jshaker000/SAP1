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

  wire counter_max      = counter == INSTRUCTION_STEPS[STEP_WIDTH-1:0] - 1;
  wire advance_counter  = mclk_en & ~i_halt & ~reset_counter;
  wire reset_counter    = mclk_en & ~i_halt & (counter_max | i_adv);

  always @(negedge mclk) counter <= advance_counter  ? counter + {{STEP_WIDTH-1{1'b0}},1'b1} :
                                    reset_counter    ? {STEP_WIDTH{1'b0}}                    :
                                    counter;
  assign o_data = counter;
endmodule

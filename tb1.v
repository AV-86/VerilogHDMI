`timescale 1ns/1ps
module tb;

  reg pix_clk;
  reg tmds_clk;

	wire signal_r;
	wire signal_g;
	wire signal_b;

  initial pix_clk = 0;
  initial tmds_clk = 0;
  
  always #20 pix_clk = ~pix_clk;
  always #2 tmds_clk = ~tmds_clk;

  mydvi dut(
    .pix_clk(pix_clk),
    .tmds_clk(tmds_clk),

    .signal_r(signal_r),
    .signal_g(signal_g),
    .signal_b(signal_b)
  );
  
  initial begin
    #4000 $stop;
  end

endmodule
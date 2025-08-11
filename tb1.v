`timescale 1ns/1ps
module tb;

  reg clk;

	wire HDMI_CLK;
	wire HDMI_D0;
	wire HDMI_D1;
	wire HDMI_D2;

  initial clk = 0;
  
  always #10 clk = ~clk; 
	
 
  main dut(
	.clk(clk),

	.HDM_CLK(HDMI_CLK),
	.HDM_D0(HDMI_D0),
	.HDM_D1(HDMI_D1),
	.HDM_D2(HDMI_D2)
  );
  
  initial begin
    #4000 $stop;
  end

endmodule


module main(
	input wire key1,
	input wire key2,
	
	input wire clk,

	
	output wire led5,
	output wire led6,
	
	output wire [7:0] disp_7seg_segments,
	output wire [2:0] disp_7seg_dig,
	
	output wire HDMI_CLK,
	output wire HDMI_D0,
	output wire HDMI_D1,
	output wire HDMI_D2
);

	wire tmds_clk;
	wire pix_clk;

	PLL2 PLL2_inst(.inclk0(clk), .c1(tmds_clk), .c0(pix_clk));
	
	assign HDMI_CLK = pix_clk;
	
	
	reg [31:0] cnt1;
	
	assign led5 = cnt1[23];
	
	always@(posedge HDMI_CLK)begin
		cnt1 <= cnt1 + 1;		
	end
	
	mydvi mydvi_inst1(
		.key1(key1),
		.key2(key2),

		.pix_clk(pix_clk),
		.tmds_clk(tmds_clk),

		.signal_r(HDMI_D2),
		.signal_g(HDMI_D1),
		.signal_b(HDMI_D0),

		.disp_7seg_segments(disp_7seg_segments),
		.disp_7seg_dig(disp_7seg_dig)	
	);

endmodule





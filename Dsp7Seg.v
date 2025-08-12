module LowLevel3_7Seg(
	input wire seg_sw_clk,
	input wire [7:0] Dig1,
	input wire [7:0] Dig2,
	input wire [7:0] Dig3,

	output wire[7:0] Seg,
	output wire[2:0] Dig
);

	reg [1:0] curr_dig;

	assign Seg = (curr_dig == 0) ?  ~Dig1 : (curr_dig == 1) ? ~Dig2 : (curr_dig == 2) ? ~Dig3 : 8'b00000000;
	assign Dig = (curr_dig == 0) ?  1 : (curr_dig == 1) ? 2 : (curr_dig == 2) ? 4 : 3'b000;

	always @(posedge seg_sw_clk) begin
		curr_dig <= (curr_dig == 2) ? 0 : curr_dig + 1;
	end
endmodule

module DigToSegs(input wire[3:0] DigVal, output wire [7:0] Seg);
	assign Seg = 
	(DigVal == 0) ? 8'b00111111 :
	(DigVal == 1) ? 8'b00000110 :
	(DigVal == 2) ? 8'b01011011 :
	(DigVal == 3) ? 8'b01001111 :
	(DigVal == 4) ? 8'b01100110 :
	(DigVal == 5) ? 8'b01101101 :
	(DigVal == 6) ? 8'b01111101 :
	(DigVal == 7) ? 8'b00000111 :
	(DigVal == 8) ? 8'b01111111 :
	(DigVal == 9) ? 8'b01101111 :

	(DigVal == 10) ? 8'b01110111 :
	(DigVal == 11) ? 8'b01111100 :
	(DigVal == 12) ? 8'b00111001 :
	(DigVal == 13) ? 8'b01011110 :
	(DigVal == 14) ? 8'b01111001 :
	(DigVal == 15) ? 8'b01110001 : 0;	
endmodule

module NumberOn3_7Seg(
	input wire seg_sw_clk,
	input wire[9:0] Num,

	output wire[7:0] Seg,
	output wire[2:0] Dig
);
	wire[3:0] Dig1Val = Num / 100;
	wire[3:0] Dig2Val = (Num / 10) % 10;
	wire[3:0] Dig3Val = Num % 10;
	
	wire[7:0] Dig1;
	wire[7:0] Dig2;
	wire[7:0] Dig3;

	DigToSegs GetDig1(.DigVal(Dig1Val), .Seg(Dig1));
	DigToSegs GetDig2(.DigVal(Dig2Val), .Seg(Dig2));
	DigToSegs GetDig3(.DigVal(Dig3Val), .Seg(Dig3));
	

	LowLevel3_7Seg indicator(
		.seg_sw_clk(seg_sw_clk),
		.Dig1(Dig1),
		.Dig2(Dig2),
		.Dig3(Dig3),

		.Seg(Seg),
		.Dig(Dig)
	);	
endmodule

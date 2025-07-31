module get_xor_xnor_encoded_9_bit(
	input wire [7:0] bits_in,
	output reg [8:0] xor_xnor_encoded_9_bit
);
	reg [3:0] n_ones_inp;
	reg xnor_xor;
	
	always @* begin
		n_ones_inp = bits_in[0]+bits_in[1]+bits_in[2]+bits_in[3]+bits_in[4]+bits_in[5]+bits_in[6]+bits_in[7];
		xnor_xor = (n_ones_inp > 4) | ((n_ones_inp == 4) & ~bits_in[0]);

		xor_xnor_encoded_9_bit[0] = bits_in[0];
		xor_xnor_encoded_9_bit[1] = xor_xnor_encoded_9_bit[0] ^ bits_in[1];
		xor_xnor_encoded_9_bit[2] = xor_xnor_encoded_9_bit[1] ^ bits_in[2];
		xor_xnor_encoded_9_bit[3] = xor_xnor_encoded_9_bit[2] ^ bits_in[3];
		xor_xnor_encoded_9_bit[4] = xor_xnor_encoded_9_bit[3] ^ bits_in[4];
		xor_xnor_encoded_9_bit[5] = xor_xnor_encoded_9_bit[4] ^ bits_in[5];
		xor_xnor_encoded_9_bit[6] = xor_xnor_encoded_9_bit[5] ^ bits_in[6];
		xor_xnor_encoded_9_bit[7] = xor_xnor_encoded_9_bit[6] ^ bits_in[7];
		xor_xnor_encoded_9_bit[8] = 1;
		xor_xnor_encoded_9_bit = xnor_xor ? ~xor_xnor_encoded_9_bit : xor_xnor_encoded_9_bit ;
	end
endmodule


module get_dvi_tmds_10_bit_from_8(
	input wire [7:0] D, // video data
	input wire DE, // video data enabled
	input wire C0, //hSync
	input wire C1, //vSync
	input wire signed [31:0] PrevBitCnt,
	
	output reg [9:0] tmds,
	output reg signed [31:0] BitCnt
);
	reg [8:0] q_m;
	reg [3:0] N1_q_m;

	get_xor_xnor_encoded_9_bit q_m_coder(.bits_in(D), .xor_xnor_encoded_9_bit(q_m));

	always @* begin
		N1_q_m = q_m[0]+q_m[1]+q_m[2]+q_m[3]+q_m[4]+q_m[5]+q_m[6]+q_m[7];
		if(~DE)begin 
			BitCnt <= 0;
			case({C1, C0})
				2'b00: tmds <= 10'b0010101011;
				2'b01: tmds <= 10'b1101010100;
				2'b10: tmds <= 10'b0010101010;
				2'b11: tmds <= 10'b1101010101;
			endcase
		end else begin
			if((PrevBitCnt == 0) || (N1_q_m == 4))begin 
				tmds[9] <= ~q_m[8];
				tmds[8] <= q_m[8];
				tmds[7:0] <= ((q_m[8]) ? q_m[7:0] : ~q_m[7:0]);

				if(~q_m[8])begin 
					BitCnt = PrevBitCnt + (8 - 2 * N1_q_m);
				end else begin
					BitCnt = PrevBitCnt + (2 * N1_q_m - 8);
				end

			end else begin
				if(((PrevBitCnt > 0) && (N1_q_m > 4)) || ((PrevBitCnt < 0) && (N1_q_m < 4)))begin
					tmds[9] <= 1;
					tmds[8] <= q_m[8];
					tmds[7:0] <= ~q_m[7:0];
					BitCnt <= PrevBitCnt + 2 * q_m[8] + (8 - 2 * N1_q_m);
				end else begin
					tmds[9] <= 0;
					tmds[8] <= q_m[8];
					tmds[7:0] <= q_m[7:0];
					BitCnt <= PrevBitCnt - 2 * ~q_m[8] + (2 * N1_q_m - 8);
				end
			end
		end

	end


endmodule


module mydvi(
	input wire tmds_clk,
	input wire pix_clk,

	output reg signal_R,
	output reg signal_G,
	output reg signal_B
);
	reg [12:0] x_cntr;
	reg [12:0] y_cntr;

	reg [9:0] OutShiftr_R;
	reg [9:0] OutShiftr_G;
	reg [9:0] OutShiftr_B;

	reg signed[31:0] PrevBitCntR;
	reg signed[31:0] PrevBitCntG;
	reg signed[31:0] PrevBitCntB;

	wire signed[31:0] BitCntR;
	wire signed[31:0] BitCntG;
	wire signed[31:0] BitCntB;


	localparam [12:0] MAX_X_ALL = 800;
	localparam [12:0] MAX_Y_ALL = 525;

	wire [9:0] tmds_r;
	wire [9:0] tmds_g;
	wire [9:0] tmds_b;

	reg hSync;
	reg vSync;
	reg DrawArea;

	get_dvi_tmds_10_bit_from_8 cdr_insr_r(
		.D(D),
		.DE(DrawArea), // video data enabled
		.C0(hSync), //hSync
		.C1(vSync), //vSync
		.PrevBitCnt(PrevBitCntR),
		
		.tmds(tmds_r),
		.BitCnt(BitCntR)
	);

	always @(posedge pix_clk) DrawArea <= (x_cntr<640) && (y_cntr<480);
	always @(posedge pix_clk) hSync <= (x_cntr>=656) && (x_cntr<752);
	always @(posedge pix_clk) vSync <= (y_cntr>=490) && (y_cntr<492);

	always @(posedge pix_clk) PrevBitCntR <= BitCntR;
	always @(posedge pix_clk) PrevBitCntG <= BitCntG;
	always @(posedge pix_clk) PrevBitCntB <= BitCntB;

	always @(posedge pix_clk) begin
		if(x_cntr == MAX_X_ALL)begin
			x_cntr <= 0;
			if(y_cntr == MAX_Y_ALL) begin
				y_cntr <= 0;
			end else begin
				y_cntr <= y_cntr + 1;
			end
		end else begin
			x_cntr <= x_cntr + 1;
		end
		
	end

	always @(posedge tmds_clk) begin
		signal_R <= OutShiftr_R[9];
		OutShiftr_R <= {OutShiftr_R[8:0], 1};
		signal_G <= OutShiftr_G[9];
		OutShiftr_G <= {OutShiftr_G[8:0], 1};
		signal_B <= OutShiftr_B[9];
		OutShiftr_B <= {OutShiftr_B[8:0], 1};
	end


endmodule

module main(
	input wire clk,
	
	output wire led5,
	output wire led6
);
endmodule





module get_xor_xnor_encoded_9_bit(
	input wire [7:0] bits_in,
	output reg [8:0] xor_xnor_encoded_9_bit
);
	reg [3:0] n_ones_inp;
	reg xnor_xor;
	
	always @* begin
		n_ones_inp = bits_in[0]+bits_in[1]+bits_in[2]+bits_in[3]+bits_in[4]+bits_in[5]+bits_in[6]+bits_in[7];
		xnor_xor = (n_ones_inp > 4) | ((n_ones_inp == 4) & (bits_in[0] == 0));

		xor_xnor_encoded_9_bit[0] = bits_in[0];
		xor_xnor_encoded_9_bit[1] = xnor_xor ? ~(xor_xnor_encoded_9_bit[0] ^ bits_in[1]) : (xor_xnor_encoded_9_bit[0] ^ bits_in[1]);
		xor_xnor_encoded_9_bit[2] = xnor_xor ? ~(xor_xnor_encoded_9_bit[1] ^ bits_in[2]) : (xor_xnor_encoded_9_bit[1] ^ bits_in[2]);
		xor_xnor_encoded_9_bit[3] = xnor_xor ? ~(xor_xnor_encoded_9_bit[2] ^ bits_in[3]) : (xor_xnor_encoded_9_bit[2] ^ bits_in[3]);
		xor_xnor_encoded_9_bit[4] = xnor_xor ? ~(xor_xnor_encoded_9_bit[3] ^ bits_in[4]) : (xor_xnor_encoded_9_bit[3] ^ bits_in[4]);
		xor_xnor_encoded_9_bit[5] = xnor_xor ? ~(xor_xnor_encoded_9_bit[4] ^ bits_in[5]) : (xor_xnor_encoded_9_bit[4] ^ bits_in[5]);
		xor_xnor_encoded_9_bit[6] = xnor_xor ? ~(xor_xnor_encoded_9_bit[5] ^ bits_in[6]) : (xor_xnor_encoded_9_bit[5] ^ bits_in[6]);
		xor_xnor_encoded_9_bit[7] = xnor_xor ? ~(xor_xnor_encoded_9_bit[6] ^ bits_in[7]) : (xor_xnor_encoded_9_bit[6] ^ bits_in[7]);
		xor_xnor_encoded_9_bit[8] = xnor_xor ? 0 : 1;

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
	wire [8:0] q_m;
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


module get_rgb(
	input wire[12:0] x,
	input wire[12:0] y,

	output reg [7:0] r,
	output reg [7:0] g,
	output reg [7:0] b
);
	reg[7:0] R_str_val;
	reg[7:0] G_str_val;
	reg[7:0] B_str_val;

	reg val_is_inc;	
	always @(posedge y[6]) begin
		if((R_str_val == 254 && val_is_inc) || (R_str_val == 0 && ~val_is_inc)) val_is_inc <= ~val_is_inc;
		R_str_val <= val_is_inc ? R_str_val + 1 : (R_str_val != 0) ? R_str_val - 1 : 0;
		G_str_val <= (R_str_val + 85 > 255) ? (val_is_inc ? 426 - R_str_val : R_str_val - 85) : R_str_val + 85;
		B_str_val <= (R_str_val + 171 > 255) ? (val_is_inc ? 340 - R_str_val : R_str_val - 171) : R_str_val + 171;
	end
	
	always @(posedge x[0]) begin
		r <= (200 < x && x < 300) ? R_str_val : 0;
		g <= (300 < x && x < 400) ? G_str_val : 0;
		b <= (400 < x && x < 500) ? B_str_val : 0;
	end
endmodule



/* region MyDVI*/
module mydvi(
	input wire pix_clk,
	input wire tmds_clk,

	output reg signal_r,
	output reg signal_g,
	output reg signal_b,

	output wire [7:0] disp_7seg_segments,
	output wire [2:0] disp_7seg_dig	
);
	
	reg signed[31:0] PrevBitCntR;
	reg signed[31:0] PrevBitCntG;
	reg signed[31:0] PrevBitCntB;

	wire signed[31:0] BitCntR;
	wire signed[31:0] BitCntG;
	wire signed[31:0] BitCntB;

	reg [12:0] x_cntr;
	reg [12:0] y_cntr;
	reg DrawArea;
	reg hSync;
	reg vSync;

	// localparam [12:0] MAX_X_ALL = 800;
	// localparam [12:0] MAX_X_DSPL = 640;
	// localparam [12:0] HOR_SYNC_START = 656;
	// localparam [12:0] HOR_SYNC_END = 752;
	// localparam [12:0] MAX_Y_ALL = 525;
	// localparam [12:0] MAX_Y_DSPL = 480;
	// localparam [12:0] VERT_SYNC_START = 490;
	// localparam [12:0] VERT_SYNC_END = 492;

	localparam [12:0] MAX_X_ALL = 1360 + 64 + 112 + 256;
	localparam [12:0] MAX_X_DSPL = 1360;
	localparam [12:0] HOR_SYNC_START = 1360 + 64;
	localparam [12:0] HOR_SYNC_END = 1360 + 64 + 112;
	localparam [12:0] MAX_Y_ALL = 768 + 4 + 6 + 17;
	localparam [12:0] MAX_Y_DSPL = 768;
	localparam [12:0] VERT_SYNC_START = 768 + 4;
	localparam [12:0] VERT_SYNC_END = 768 + 4 + 6;

	wire [9:0] tmds_r;
	wire [9:0] tmds_g;
	wire [9:0] tmds_b;

	reg [9:0] tmds_r_load;
	reg [9:0] tmds_g_load;
	reg [9:0] tmds_b_load;

	reg [9:0] shift_reg_r;
	reg [9:0] shift_reg_g;
	reg [9:0] shift_reg_b;


	wire[7:0] R; wire[7:0] G; wire[7:0] B;

	get_rgb get_rgb_inst(.x(x_cntr), .y(y_cntr), .r(R), .g(G), .b(B));
	
	get_dvi_tmds_10_bit_from_8 cdr_insr_r(.D(R), .DE(DrawArea), .C0(0),     .C1(0),     .PrevBitCnt(PrevBitCntR),.tmds(tmds_r),.BitCnt(BitCntR));
	get_dvi_tmds_10_bit_from_8 cdr_insr_g(.D(G), .DE(DrawArea), .C0(0),     .C1(0),     .PrevBitCnt(PrevBitCntG),.tmds(tmds_g),.BitCnt(BitCntG));
	get_dvi_tmds_10_bit_from_8 cdr_insr_b(.D(B), .DE(DrawArea), .C0(hSync), .C1(vSync), .PrevBitCnt(PrevBitCntB),.tmds(tmds_b),.BitCnt(BitCntB));
	
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
	
	always @(posedge pix_clk) DrawArea <= (x_cntr < MAX_X_DSPL) && (y_cntr < MAX_Y_DSPL);
	always @(posedge pix_clk) hSync <= (x_cntr >= HOR_SYNC_START) && (x_cntr < HOR_SYNC_END);
	always @(posedge pix_clk) vSync <= (y_cntr >= VERT_SYNC_START) && (y_cntr < VERT_SYNC_END);

	always @(posedge pix_clk) PrevBitCntR <= BitCntR;
	always @(posedge pix_clk) PrevBitCntG <= BitCntG;
	always @(posedge pix_clk) PrevBitCntB <= BitCntB;

	always @(posedge pix_clk) tmds_r_load <= tmds_r;
	always @(posedge pix_clk) tmds_g_load <= tmds_g;
	always @(posedge pix_clk) tmds_b_load <= tmds_b;
	
	reg [3:0] bit_cnt_r;
	reg [3:0] bit_cnt_g;
	reg [3:0] bit_cnt_b;

	always @(posedge tmds_clk) begin
		if(bit_cnt_r == 0) begin
			signal_r <= tmds_r_load[0];
			shift_reg_r <= {1'b0, tmds_r_load[9:1]};
			bit_cnt_r <= 9;
		end else begin
			signal_r <= shift_reg_r[0];
			shift_reg_r <= {1'b0, shift_reg_r[9:1]};
			bit_cnt_r <= bit_cnt_r - 1;
		end
	end

	always @(posedge tmds_clk) begin
		if(bit_cnt_g == 0) begin
			signal_g <= tmds_g_load[0];
			shift_reg_g <= {1'b0, tmds_g_load[9:1]};
			bit_cnt_g <= 9;
		end else begin
			signal_g <= shift_reg_g[0];
			shift_reg_g <= {1'b0, shift_reg_g[9:1]};
			bit_cnt_g <= bit_cnt_g - 1;
		end
	end

	always @(posedge tmds_clk) begin
		if(bit_cnt_b == 0) begin
			signal_b <= tmds_b_load[0];
			shift_reg_b <= {1'b0, tmds_b_load[9:1]};
			bit_cnt_b <= 9;
		end else begin
			signal_b <= shift_reg_b[0];
			shift_reg_b <= {1'b0, shift_reg_b[9:1]};
			bit_cnt_b <= bit_cnt_b - 1;
		end
	end

/* region debug*/
	reg[31:0] disp_7seg_clk_div_ntr;
	always @(posedge pix_clk) disp_7seg_clk_div_ntr <= disp_7seg_clk_div_ntr + 1;
	NumberOn3_7Seg NumberOn3_7Seg_inst(
		.seg_sw_clk(disp_7seg_clk_div_ntr[10]),
		.Num(42),

		.Seg(disp_7seg_segments),
		.Dig(disp_7seg_dig)
	);	

/*endregion debug*/

/*region not synthesized */
	initial begin
        x_cntr = 0;
        y_cntr = 0;

		PrevBitCntR = 0;
		PrevBitCntG = 0;
		PrevBitCntB = 0;
		tmds_r_load = 0;
		tmds_g_load = 0;
		tmds_b_load = 0;

		shift_reg_r = 0;
		shift_reg_g = 0;
		shift_reg_b = 0;

		bit_cnt_r = 0;
		bit_cnt_g = 0;
		bit_cnt_b = 0;

		DrawArea = 0;
		hSync = 0;
		vSync = 0;
    end
/* endregion not synthesized */

endmodule
/* endregion MyDVI*/

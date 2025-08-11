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

module mydvi(
	input wire pix_clk,
	input wire tmds_clk,

	output reg signal_r,
	output reg signal_g,
	output reg signal_b
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

	localparam [12:0] MAX_X_ALL = 800;
	localparam [12:0] MAX_Y_ALL = 525;

	wire [9:0] tmds_r;
	wire [9:0] tmds_g;
	wire [9:0] tmds_b;

	reg [9:0] tmds_r_load;
	reg [9:0] tmds_g_load;
	reg [9:0] tmds_b_load;

	reg [9:0] shift_reg_r;
	reg [9:0] shift_reg_g;
	reg [9:0] shift_reg_b;


	
	get_dvi_tmds_10_bit_from_8 cdr_insr_r(.D(145), .DE(DrawArea), .C0(0),     .C1(0),     .PrevBitCnt(PrevBitCntR),.tmds(tmds_r),.BitCnt(BitCntR));
	get_dvi_tmds_10_bit_from_8 cdr_insr_g(.D(200), .DE(DrawArea), .C0(0),     .C1(0),     .PrevBitCnt(PrevBitCntG),.tmds(tmds_g),.BitCnt(BitCntG));
	get_dvi_tmds_10_bit_from_8 cdr_insr_b(.D(100), .DE(DrawArea), .C0(hSync), .C1(vSync), .PrevBitCnt(PrevBitCntB),.tmds(tmds_b),.BitCnt(BitCntB));
	
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
	
	always @(posedge pix_clk) DrawArea <= (x_cntr<640) && (y_cntr<480);
	always @(posedge pix_clk) hSync <= (x_cntr>=656) && (x_cntr<752);
	always @(posedge pix_clk) vSync <= (y_cntr>=490) && (y_cntr<492);

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
			signal_r <= tmds_r_load[9];
			shift_reg_r <= {tmds_r_load[8:0], 1'b0};
			bit_cnt_r <= 9;
		end else begin
			signal_r <= shift_reg_r[9];
			shift_reg_r <= {shift_reg_r[8:0], 1'b0};
			bit_cnt_r <= bit_cnt_r - 1;
		end
	end

	always @(posedge tmds_clk) begin
		if(bit_cnt_g == 0) begin
			signal_g <= tmds_g_load[9];
			shift_reg_g <= {tmds_g_load[8:0], 1'b0};
			bit_cnt_g <= 9;
		end else begin
			signal_g <= shift_reg_g[9];
			shift_reg_g <= {shift_reg_g[8:0], 1'b0};
			bit_cnt_g <= bit_cnt_g - 1;
		end
	end

	always @(posedge tmds_clk) begin
		if(bit_cnt_b == 0) begin
			signal_b <= tmds_b_load[9];
			shift_reg_b <= {tmds_b_load[8:0], 1'b0};
			bit_cnt_b <= 9;
		end else begin
			signal_b <= shift_reg_b[9];
			shift_reg_b <= {shift_reg_b[8:0], 1'b0};
			bit_cnt_b <= bit_cnt_b - 1;
		end
	end
	

/* not synthesized */
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
/* end not synthesized */

endmodule


module main(
	input wire clk,
	
	
	output wire led5,
	output wire led6,
	
	output wire HDMI_CLK,
	output wire HDMI_D0,
	output wire HDMI_D1,
	output wire HDMI_D2
);

	wire tmds_clk;
	wire pix_clk;

	PLL1 PLL1_inst(.inclk0(clk), .c0(tmds_clk), .c1(pix_clk));
	
	assign HDMI_CLK = pix_clk;
	
	
	reg [31:0] cnt1;
	
	assign led5 = cnt1[23];
	
	always@(posedge HDMI_CLK)begin
		cnt1 <= cnt1 + 1;		
	end
	
	mydvi mydvi_ist1(
		.pix_clk(pix_clk),
		.tmds_clk(tmds_clk),

		.signal_r(HDMI_D0),
		.signal_g(HDMI_D1),
		.signal_b(HDMI_D2)
	);

endmodule





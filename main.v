
// module TMDS_encoder(
// 	input clk,
// 	input [7:0] VD,  // video data (red, green or blue)
// 	input [1:0] CD,  // control data
// 	input VDE,  // video data enable, to choose between CD (when VDE=0) and VD (when VDE=1)
// 	output reg [9:0] TMDS = 0
//     );

//     wire [3:0] Nb1s = VD[0] + VD[1] + VD[2] + VD[3] + VD[4] + VD[5] + VD[6] + VD[7];
//     wire XNOR = (Nb1s>4'd4) || (Nb1s==4'd4 && VD[0]==1'b0);
//     wire [8:0] q_m = {~XNOR, q_m[6:0] ^ VD[7:1] ^ {7{XNOR}}, VD[0]};

//     reg [3:0] balance_acc = 0;
//     wire [3:0] balance = q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7] - 4'd4;
//     wire balance_sign_eq = (balance[3] == balance_acc[3]);
//     wire invert_q_m = (balance==0 || balance_acc==0) ? ~q_m[8] : balance_sign_eq;
//     wire [3:0] balance_acc_inc = balance - ({q_m[8] ^ ~balance_sign_eq} & ~(balance==0 || balance_acc==0));
//     wire [3:0] balance_acc_new = invert_q_m ? balance_acc-balance_acc_inc : balance_acc+balance_acc_inc;
//     wire [9:0] TMDS_data = {invert_q_m, q_m[8], q_m[7:0] ^ {8{invert_q_m}}};
//     wire [9:0] TMDS_code = CD[1] ? (CD[0] ? 10'b1010101011 : 10'b0101010100) : (CD[0] ? 10'b0010101011 : 10'b1101010100);

//     always @(posedge clk) TMDS <= VDE ? TMDS_data : TMDS_code;
//     always @(posedge clk) balance_acc <= VDE ? balance_acc_new : 4'h0;
// endmodule



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

module mydvi(
	input wire tmds_clk,
	input wire pix_clk
);
	reg [12:0] x_cntr;
	reg [12:0] y_cntr;

	localparam [12:0] MAX_X_ALL = 720;
	localparam [12:0] MAX_Y_ALL = 512;

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


endmodule

module main(
	input wire clk,
	
	output wire led5,
	output wire led6
);
endmodule


module ge


`timescale 1ns/1ps
module tb;

  reg  [7:0] in_data;
  wire [8:0] out_data;

  integer i;

  // Подключение тестируемого устройства
  get_xor_xnor_encoded_9_bit dut (
    .bits_in(in_data),
    .xor_xnor_encoded_9_bit(out_data)
  );

  initial begin
    $display("=== testing... ===");

    // Перебор нескольких входных комбинаций
    for (i = 0; i < 10; i = i + 1) begin
      in_data = i * 17;  // Примеры: 0, 17, 34, ..., 153
      #5;
      $display("Вход: %b | Выход: %b", in_data, out_data);
    end

    $display("=== Конец теста ===");
    $stop;
  end

endmodule


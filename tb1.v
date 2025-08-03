// `timescale 1ns/1ps
// module tb;
//   reg [7:0] test_D;
//   reg test_DE;
//   reg test_C0;
//   reg test_C1;
//   reg signed [31:0] test_PrevBitCnt;
  
//   wire [9:0] test_out_tmds;
//   wire signed [31:0] test_out_BitCnt;

//   get_dvi_tmds_10_bit_from_8 dut (
// 	.D(test_D), // video data
// 	.DE(test_DE), // video data enabled
// 	.C0(test_C0), //hSync
// 	.C1(test_C1), //vSync
// 	.PrevBitCnt(test_PrevBitCnt),
	
// 	.tmds(test_out_tmds),
// 	.BitCnt(test_out_BitCnt)
//   );

//   initial begin
//     #10 begin
//       test_D = 8'hff;
//       test_DE = 1;
//       test_C0 = 0;
//       test_C1 = 0;
//       test_PrevBitCnt = 0;
//     end

//     #10 begin
//       test_D = 8'h00;
//       test_DE = 1;
//       test_C0 = 0;
//       test_C1 = 0;
//       test_PrevBitCnt = 2;
//     end

//     #10 begin
//       test_D = 8'hAA;
//       test_DE = 1;
//       test_C0 = 0;
//       test_C1 = 0;
//       test_PrevBitCnt = -2;
//     end

//     #10 begin
//       test_D = 8'h55;
//       test_DE = 1;
//       test_C0 = 0;
//       test_C1 = 0;
//       test_PrevBitCnt = 2;
//     end


//     #10 $stop;
//   end
// endmodule


`timescale 1ns/1ps
module tb;
  
  reg test_in_tmds_clk;
  reg test_in_pix_clk;

  wire test_out_signal_R;
  wire test_out_signal_G;
  wire test_out_signal_B;

  wire [9:0] test_out_tst_tmds_r;
  wire signed [31:0] test_out_tst_PrevBitCntR;

  initial test_in_tmds_clk = 0;
  always #4 test_in_tmds_clk = ~test_in_tmds_clk;

  initial test_in_pix_clk = 0;
  always #40 test_in_pix_clk = ~test_in_pix_clk;


  mydvi dut(
    .tmds_clk(test_in_tmds_clk),
    .pix_clk(test_in_pix_clk),

    .signal_R(test_out_signal_R),
    .signal_G(test_out_signal_G),
    .signal_B(test_out_signal_B),

    .tst_tmds_r(test_out_tst_tmds_r),
    .tst_PrevBitCntR(test_out_tst_PrevBitCntR)
  );
  
  initial begin
    
    #400 $stop; // stop simulation after 100 ns
  end
endmodule

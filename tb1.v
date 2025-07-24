`timescale 1ns/1ps
module tb;
  reg [7:0] bits_in;
  wire [8:0] xor_xnor_encoded_9_bit;

  get_xor_xnor_encoded_9_bit dut (
    .bits_in(bits_in),
    .xor_xnor_encoded_9_bit(xor_xnor_encoded_9_bit)
  );

  initial begin
    bits_in = 8'b10110011;
    #10 bits_in = 8'b00011100;
    #10 bits_in = 8'b11110000;
    #10 $stop;
  end
endmodule
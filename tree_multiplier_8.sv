`timescale 1 ns/10 ps
//change to being sequential?
//unoptimized at the moment as I'm using all 8 bit adders
module tree_multiplier_8 (//the leftmost 8 bits from the multiplication are lost
    input wire clk,
	input wire srst,
	input wire [7:0] A,
	input wire [7:0] B,
	output reg [7:0] out
);
  
  //this monstrosity should hopefully be synthesized as a tree adder instead of it all being done sequentially
  reg [7:0] A7 = '0;
  reg [7:0] A6 = '0;
  reg [7:0] A5 = '0;
  reg [7:0] A4 = '0;
  reg [7:0] A3 = '0;
  reg [7:0] A2 = '0;
  reg [7:0] A1 = '0;
  reg [7:0] A0 = '0;
  
  reg [7:0] S13;
  reg [7:0] S12;
  reg [7:0] S11;
  reg [7:0] S10;
  reg [7:0] S21;
  reg [7:0] S20;
	always @(*) begin
		A7 = (A[7] & B) << 7;
           	A6 = (A[6] & B) << 6;
           	A5 = (A[5] & B) << 5;
           	A4 = (A[4] & B) << 4;
           	A3 = (A[3] & B) << 3;
           	A2 = (A[2] & B) << 2;
           	A1 = (A[1] & B) << 1;
           	A0 = (A[0] & B) << 0;
			//summing
           	S13 = A7 + A6;
           	S12 = A5 + A4;
           	S11 = A3 + A2;
           	S10 = A1 + A0;
			
          	S21 = S13 + S12;
          	S20 = S11 + S10;
			
			out = S21 + S20;
	end

endmodule
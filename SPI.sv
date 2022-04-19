module SPI #(parameter WIDTH, parameter DEPTH=512)(//reconfigure to make as many parameters otional as possible
    input clk,
	input srst,
	inout MISO,//master in slave out
	inout MOSI,//master out, slave in 
    input [WIDTH-1:0] din,
    input wr_en,
    input rd_en,
	input master,//if false assume slave
    output reg [WIDTH-1:0] dout=0,
    output full,
    output empty,
    output valid,
    output [$clog2(DEPTH)-1:0] data_count
);
	parameter BITS = $clog2(DEPTH) - 1;
	reg [WIDTH-1:0] ram [DEPTH-1: 0];
	reg [BITS:0] read = 0;
	reg [BITS:0] write = 0;
	assign data_count = write - read;
	assign valid = data_count != 0;
	assign empty = data_count == 0;
	assign full = data_count == DEPTH;
	
	
	
	


endmodule
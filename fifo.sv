module fifo #(parameter WIDTH, parameter DEPTH)( //this is first word fall through
    input clk,
	input srst,
    input [WIDTH-1:0] din,
    input wr_en,
    input rd_en,
    output logic [WIDTH-1:0] dout=0,
    output logic full,
    output logic empty,
    output logic valid,
    output logic [$clog2(DEPTH)-1:0] data_count
);
	parameter BITS = $clog2(DEPTH) - 1;
	reg [WIDTH-1:0] ram [DEPTH-1: 0];
	reg [BITS:0] read = 0;
	reg [BITS:0] write = 0;
	assign data_count = write - read;
	assign valid = data_count != 0;
	assign empty = data_count == 0;
	assign full = data_count == DEPTH;
	//writing logic
	always_ff @(posedge clk) begin
		if(srst)
			write <= 0;
		else if(wr_en && !full) begin
			write <= write == DEPTH-1 ? 0 : write + 1;
			ram[write] <= din;
		end else
			write <= write;
	end
	
	//reading logic
	always_ff @(posedge clk) begin
		if(srst) begin
			read <= 0;
			dout <= 0;
		end else if(rd_en && data_count > 0) begin
			read <= read == DEPTH-1 ? 0 : read + 1;
			dout <= ram[read == DEPTH-1 ? 0 : read + 1];//to ensure first word fall through behavior it grabs one ahead so it's ready for the next cycle
		end else begin
			read <= read;
			dout <= ram[read];//ensures first word fall through
		end
	end


endmodule
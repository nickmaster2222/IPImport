module fifo #(parameter WIDTH=8, parameter DEPTH=512)( //this is first word fall through
    input clk,
	input srst,
    input [WIDTH-1:0] din,
    input wr_en,
    input rd_en,
    output reg [WIDTH-1:0] dout=0,
    output full,
    output empty,
    output valid,
    output reg [$clog2(DEPTH)-1:0] data_count
);
	parameter BITS = $clog2(DEPTH) - 1;
	reg [WIDTH-1:0] ram [DEPTH-1: 0];
	reg [BITS:0] read = 0;
	reg [BITS:0] write = 0;
	//reg side = 0;//0 means the write pointer is on the right of the read pointer, 1 is the opposite
	assign valid = data_count != 0;
	assign empty = data_count == 0;
	assign full = data_count == DEPTH;
	
	//tracking amount of data in fifo
	always @(posedge clk) begin//could be replaced with somthing that just tracks what side of the read pointer the write pointer is on
		if (rd_en && !empty && !wr_en)
			data_count <= data_count - 1;
		else if (!rd_en && wr_en && !full)
			data_count <= data_count + 1;
		else if(wr_en && rd_en) begin//potential problems arrise if both rd_en and wr_en are asserted at the same time while the fifo is empty
			if(empty)//if the fifo is empty one shouldn't be able to remove data and the read would fail, therefore only the write would succeed
				data_count <= data_count + 1;
			else
				data_count <= data_count;
		end else 
			data_count <= data_count;
	end
	
	//writing logic
	always @(posedge clk) begin
		if(srst)
			write <= 0;
		else if(wr_en && !full) begin
			write <= write == DEPTH-1 ? 0 : write + 1;
			ram[write] <= din;
		end else
			write <= write;
	end
	
	//reading logic
	always @(posedge clk) begin
		if(srst) begin
			read <= 0;
			dout <= '0;
		end else if(rd_en && data_count > 0) begin
			read <= read == DEPTH-1 ? 0 : read + 1;
			dout <= ram[read == DEPTH-1 ? 0 : read + 1];//to ensure first word fall through behavior it grabs one ahead so it's ready for the next cycle
		end else begin
			read <= read;
			dout <= empty ? '0 : ram[read];//ensures first word fall through and doesn't leak old data if empty
		end
	end


endmodule
//unlike a normal fifo this one is capable of having multiple read and write ports, bewarer synthesizing this though as the synthesizer might turn it to registers
//max of 8 read and 8 write ports
//I made this into a seperate module as it's likely going to have bugs and will be both slower and significantly larger/more complex than its predesessor
//read is from the perspective of the user and so is the data going out and write is vice versa
module fifo #(parameter WIDTH, parameter DEPTH, parameter READ_PORTS=1, parameter WRITE_PORTS = 1)( //this cannot be first word fall through due to the read ports not having to be accessed in order
    input clk,
	input srst,
    input [WIDTH-1:0] din [WRITE_PORTS-1],
    input wr_en [$clog2(WRITE_PORTS)-1:0],//writing from the user's perspective
	output logic rd_fail [$clog2(WRITE_PORTS)-1:0],//whether a write failed as there wasn't enough space to fufil all attempted writes
    input rd_en [$clog2(READ_PORTS)-1:0],//reading from the user's perspective
	output logic rd_fail [$clog2(READ_PORTS)-1:0],//whether a read failed to get data as there wasn't enough to fufil all requests
    output logic [WIDTH-1:0] dout [READ_PORTS-1:0],
    output logic full,
    output logic empty,
    output logic valid,
    output logic [$clog2(DEPTH)-1:0] data_count,
);
	//pulling is how many values are going to be read this clock cycle, the count of all the 1s in rd_en
	//this function returns 
	//max of 8 read/write ports
	function automatic [$clog2(DEPTH)-1:0] get_address(input [$clog2(DEPTH)-1:0] base, input [2:0] offset);
        if(base + offset >= DEPTH)
			return base + offset - DEPTH;
		else
			return base + offset;
	endfunction
	
	parameter BITS = $clog2(DEPTH) - 1;
	reg [WIDTH-1:0] ram [DEPTH-1: 0];
	reg [BITS:0] read [READ_PORTS-1:0] = 0;
	reg [BITS:0] write [WRITE_PORTS-1:0] = 0;
	assign data_count = write[0] - read[0];
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
	
	logic read_bit_sum;
	always_comb begin
        reg [$clog2(READ_PORTS)-1:0] count = '0;
			foreach(rd_en[i]) begin
                count += rd_en[i];
            end
			return count;
    end
	
	reg read_count = 0;
	always_ff @(posedge clk) begin
		if(srst) begin
			foreach(read[i]) begin
				read[i] <= '0;
				dout[i] <= '0;
            end
		end else if(read_bit_sum > 0) begin//any read bits set?
            
        end else begin//no read bits set so 
            
        end
	end


endmodule
module skid_buf #(parameter WIDTH)(//this is first word fall through
    input clk,
	input srst,
	input i_valid,	//whether the data coming from input is ready
	output o_ready,	//whether the skid buffer is ready for data
	input [WIDTH-1:0] in,
	output o_valid,	//whether the data going to the output is valid
	input i_ready,	//whether the output module is ready for data
	output [WIDTH-1:0] out,
);
	reg [WIDTH-1:0] data;
	reg data_valid = 0;
	always @(posedge clk) begin
		if(srst) begin
			data <= '0;
			o_ready <= 0;
			data_valid <= 0;
		end else begin
			if(i_valid && i_ready) begin//out will be equal to in
				data <= '0;
				data_valid <= 0;
				o_ready = 0;
			end else if(i_valid && !i_ready) begin//need to store into buffer
				data <= in;
				data_valid <= 1;
				o_ready <= 0;
			end else if(!i_valid && i_ready) begin
				if(data_valid)
					o_ready <= 1;
				else begin
					o_ready <= 0;
				data <= '0;
				data_valid <= 0;
			end else begin
				data <= data;
				o_ready <= 0;
				data_valid <= data_valid;
			end
		end
	end
	
	always_comb begin
		if(data_valid && i_ready) begin
			out = data;
			o_valid = 1;
		end else if(i_valid && i_ready) begin
			if(data_valid)
				out = data;
			else begin
				out = in;
			o_valid = 1;
		end else begin
			out = 0;
			o_valid = 0;
		end
	end


endmodule
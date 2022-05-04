//UNTESTED

//includes a register so that this can be used anywhere a register would've been used to assist in timing-closure for pipelined designs
module skid_buf #(parameter WIDTH)(//FSM might be a better approach here
    input clk,
	input srst,
	input i_valid,	//whether the data coming from input is ready
	output reg o_ready,	//whether the skid buffer is ready for data
	input [WIDTH-1:0] in,
	output reg o_valid,	//whether the data going to the output is valid
	input i_ready,	//whether the output module is ready for data
	output reg [WIDTH-1:0] out,
);
	reg [WIDTH-1:0] r_data;
	reg r_data_valid = 0;
	always @(posedge clk) begin
		if(srst) begin
			r_data <= '0;
			o_ready <= 0;
			r_data_valid <= 0;
			out <= '0;
			o_valid = 0;
		end else begin
			if(i_valid && i_ready) begin//out will be equal to in or the data in r_data
				r_data <= '0;
				r_data_valid <= 0;
				o_ready <= 1;
				out <= r_data_valid ? r_data : in;
				o_valid <= 1;
			end else if(i_valid && !i_ready) begin//need to store into buffer
				r_data <= in;
				r_data_valid <= 1;
				o_ready <= 0;
				out <= in;
				o_valid <= 1;
			end else if(!i_valid && i_ready) begin
				o_ready <= 1;
				r_data <= '0;
				r_data_valid <= 0;
				out <= r_data_valid ? r_data : '0;
				o_valid <= r_data_valid;
			end else begin
				r_data <= r_data;
				o_ready <= r_data_valid;
				r_data_valid <= r_data_valid;
				out <= r_data_valid ? r_data : '0;
				o_valid <= r_data_valid;
			end
		end
	end


endmodule
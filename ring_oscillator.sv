import types::*;
//generates WIDTH bits of random numbers that, in theory, change every clock cycle using a ring oscillator
//this should be used to seed random number generators, though, not as an independant RNG due to the inherent lack of cycle to cycle randomness
module ring_oscillator #(WIDTH=1)(
    input clk,
	output reg [WIDTH-1:0] out
);//this will use 5 depth inverter chains because why not

	(*DONT_TOUCH="true"*)wire [4:0] rings [WIDTH-1:0];

	genvar i;
	generate
		for(i = 0; i < WIDTH; i = i + 1) begin
			assign rings[i][0] = ~rings[i][4];
			assign rings[i][1] = ~rings[i][0];
			assign rings[i][2] = ~rings[i][1];
			assign rings[i][3] = ~rings[i][2];
			assign rings[i][4] = ~rings[i][3];
		end
		always_ff @(posedge clk) begin
			for(i = 0; i < WIDTH; i = i + 1) begin
				out[i] = rings[i][0];//samples on clock edge to stop potential metastability issues on the sampler side
			end
		end
	endgenerate

endmodule

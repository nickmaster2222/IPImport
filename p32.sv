//32 bit posit
import imports::*;

typedef struct {
	reg sign,
	reg [7:0] exponent,//exponent in value is this -127, giving a range of -127, 127
	reg [31:8] fraction
} fp32;

function automatic fp32 add(input fp32 f1, input fp32 f2) begin
    fp32 fp1 = f1;
	fp32 fp2 = f2;
	//first determine which closer
	u8 fp1_e_dist = `b01111111 & (fp1.exponent - 127)
endfunction
	

endmodule
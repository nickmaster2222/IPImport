`include "fifo.sv";
`include "types.sv"
//this calculates the rolling total of a fixed size window of an incliming data stream
module rolling_total #(parameter WIDTH, parameter DEPTH)(
    input clk,
	input srst,
	input en,
    input [WIDTH-1:0] din,
    output logic [WIDTH-1 + $clog2(DEPTH):0] total=0,//rolling total
    output logic valid,
);
	logic srst, wr_en, rd_en, full, empty, valid;
	
	fifo #(WIDTH, DEPTH) uart_fifo(
        .clk,
        .srst,
        .din,
        .wr_en,
        .rd_en,
        .dout,
        .full,
        .empty,
        .valid,
        .data_count
    );
	logic reseting = 0;//if this is true this is in reset mode and won't respond to any requests
	//reset will clear one item from the fifo per clock cycle until it's empty. valid will be low while resetting and high when done, srst on;y needs to go high for one clock cycle
	always_ff @(posedge clk) begin
        if(srst || reseting) begin
            wr_en
        end else begin
            
        end
    end

endmodule
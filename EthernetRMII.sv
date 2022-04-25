//WDITH is word width for a TX/RX buffer of depth DEPTH
//SPEED either equals 10 or 100, try something different and it won't turn out well
`include "fifo.sv"

interface RMII;
	logic ref_clk, md_clk;
	logic [1:0] RX, TX;
	logic tx_en, rx_er, crs_dv;
	logic mdio;
endinterface

module EthernetRMII #(parameter WIDTH, parameter DEPTH=512, parameter SPEED)(
    input clk,
	input ref_clk,//50 mhz
	input srst,
	input [$clog2(WIDTH):0] RX,//master in slave out
	input rx_en,
	output reg [$clog2(WIDTH):0] TX,
	output reg tx_valid,
	input [31:0] COMRX,//how the user communicates with the controller of the module
	output reg [31:0] COMTX,
	RMII PHY
);
	parameter BITS = $clog2(DEPTH) - 1;
	
	
	
	
	


endmodule
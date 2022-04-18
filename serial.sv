`timescale 1ns / 1ps

module fifo #(parameter WIDTH, parameter DEPTH=512)( //this is first word fall through
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
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/20/2021 12:04:08 PM
// Design Name: 
// Module Name: serial_transmitter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "fifo.sv"
module serial_reciever #(parameter CLK_IN=0, parameter BAUD=0, parameter DEPTH=512)(
    input clk,
    input wire RX,
    input rd_en,
    output empty,
    output full,
    output [7:0] dout,
    output [8:0] data_count//,
    //input [15:0] count_for_baud //max clock division of 2^16 -1
);
    import types::*;
    parameter count_for_baud = CLK_IN / BAUD;
    
    reg srst = 0; //I don't use reset at the moment
    reg wr_en = 0;
    u8 din = 0;
    wire valid;
    fifo #(8, DEPTH) uart_fifo(
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

    u16 clock_count = 0; //internal count to clock divide for proper baud rate and extra bit so it can be signed
    u8 shift_reg = 0;
    u3 data_pos = 0;
    u16 RX_count = 0;//will hace to go up to half of count_for_baud
    u32 rx_average = 0;

    enum {START_INCOMING='b001, DATA_INCOMING='b010, STOP_INCOMING='b100} current_state = START_INCOMING;
    always_ff @(posedge clk) begin
        //clock_count = clock_count + 1;
        case(current_state)
            START_INCOMING: begin
                data_pos <= 0;
                if(RX_count == count_for_baud) begin	//to decrease possible false positives/decrease their impact, maybe remove or change since on a really noisy/ringing line this won't work properly as if the noise makes it go below the detection voltage too often for too long this will make the predicted clock be too different from the actual
														//I could do something similar to what I do below and have a shifting window where if the average goes below .5 I count that as a falling clock edge with some logic to determine when exactly that happened, that part will be hard and doing this without excessive logic/memory usage will be hard
					clock_count <= 0;
                    current_state <= DATA_INCOMING;
                    RX_count <= 0;
                end else if(!RX) begin //start bit detection to sync clock for rest of byte
                    RX_count <= RX_count + 1;
            end
            DATA_INCOMING: begin
                if(clock_count == count_for_baud) begin
                    clock_count <= 0;

                    if(data_pos == 7) begin //end of data reached
                        current_state <= STOP_INCOMING;
                        rx_average <= 0;//should help with ringing as it's measuring the average voltage instead of the voltage at one point in time
                        data_pos <= 0;
                        din <= {rx_average > count_for_baud / 2 ? 1 : 0, shift_reg[7:1]}; //shifts by one in proccess
                        wr_en <= 1;
                    end else begin
                        rx_average <= 0;
                        shift_reg <= {rx_average > count_for_baud / 2 ? 1 : 0, shift_reg[7:1]};
                        data_pos <= data_pos + 1;
                    end
                end else begin
                    clock_count <= clock_count + 1;
                    rx_average <= rx_average + RX;
                end
            end
            STOP_INCOMING: begin
                wr_en <= 0;
                din <= 0;
                if(RX)
                    current_state <= START_INCOMING; //only needed for falling edge detection purposes in START_INCOMING
                shift_reg <= 0;
            end
            default: begin
                current_state <= START_INCOMING;
                din <= 0;
                shift_reg <= 0;
            end
        endcase
    end
endmodule

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/20/2021 12:04:08 PM
// Design Name: 
// Module Name: serial_transmitter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "fifo.sv";
module serial_transmitter #(parameter CLK_IN=0, parameter BAUD=0, parameter DEPTH=512)( //no in built FIFO as of yet
    input clk,
    output reg TX,
    input wr_en, //is there new data on this clock edge
    output full,
    input [7:0] din,
    output [8:0] data_count
    //input [15:0] count_for_baud //max clock division of 2^16 -1
);
    parameter count_for_baud = CLK_IN / BAUD;
    
    import types::*;
    reg srst = 0; //I don't use reset at the moment
    reg rd_en = 0;

    wire empty;
    wire [7:0] dout;
    wire valid;//whether the output data on the fifo is valid
    fifo #(8, DEPTH) uart_fifo(
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

    enum {WAITING='b00001, START_SENDING='b00010, DATA_SENDING='b00100, WAITING_AFTER_DATA='b01000, STOP_SENDING='b10000} current_state = WAITING;




    logic [15:0] clock_count = count_for_baud; //internal count to clock divide for proper baud rate
    logic [7:0] shift_reg = 0;

    logic [2:0] shift_pos = 0;



    always_ff @(posedge clk) begin
        case(current_state)
            WAITING: begin //send out a flag when it goes into waiting mode to see if this is duplicating characters
                TX <= 1;
                if(valid) begin
                    current_state <= START_SENDING;
                    shift_reg <= dout;
                    rd_en <= 1;
                end
            end
            START_SENDING: begin
                rd_en <= 0;
                TX <= 0;
                shift_pos <= 0;
                clock_count <= 0;
                current_state <= DATA_SENDING; //no delay needed here since DATA_SENDING starts instead of ends with a delay
            end
            DATA_SENDING: begin
                if(clock_count == count_for_baud) begin
                    clock_count <= 0;
                    TX <= shift_reg[shift_pos];
                    shift_pos <= shift_pos + 1;
                    if(shift_pos == 7)
                        current_state <= WAITING_AFTER_DATA;
                end else
                    clock_count <= clock_count + 1;
            end
            WAITING_AFTER_DATA: begin
                shift_reg <= 0;
                if(clock_count == count_for_baud) begin
                    clock_count <= 0;
                    current_state <= STOP_SENDING;
                end else
                    clock_count <= clock_count + 1;

            end
            STOP_SENDING: begin
                TX <= 1;
                if(clock_count == count_for_baud) begin
                    clock_count <= 0;
                    current_state <= valid ? START_SENDING : WAITING;
                    if(valid) begin
                        shift_reg <= dout;
                        rd_en <= 1;
                    end
                end else
                    clock_count <= clock_count + 1;
            end
            default: begin
                TX <= 1;
                current_state <= WAITING;
            end
        endcase
    end
endmodule

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/19/2021 09:55:40 PM
// Design Name: 
// Module Name: serial_port
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

 
//module serial_port(
//    input clk,
//    input RX,
//    output wire TX,
//    output wire [7:0] recieved,
//    input [7:0] sending,
//    output wire data_recieved,
//    output wire data_sent,
//    input [16:0] count_for_baud_rate,
//    input data_good
//    );
    
//    serial_reciever reciever(clk, RX, recieved, data_recieved, count_for_baud_rate);
    
//    serial_transmitter transmitter(clk, TX, sending, data_sent, count_for_baud_rate, data_good);

    

    

//endmodule

module serial_port #(parameter CLK_IN=0, parameter BAUD=0)(//no in built FIFO as of yet
input clk,
input wire RX,
output TX,
output wire [7:0] din,//data going out of FPGA from perspective of user
input [7:0] dout,//data going into FPGA from perspective of user
input wr_en,
input rd_en,
output writing_full,
output reading_empty,
output reading_full,
output [11:0] din_count,
output [11:0] dout_count//,
//input [15:0] count_for_baud//max clock division of 2^16 -1
);

serial_reciever #(.CLK_IN(CLK_IN), .BAUD(BAUD)) rec(.clk, .RX, .rd_en, .empty(reading_empty), .full(reading_full), .dout(din), .data_count(din_count));


serial_transmitter #(.CLK_IN(CLK_IN), .BAUD(BAUD)) sender(.clk, .TX, .wr_en, .full(writing_full), .din(dout), .data_count(dout_count));

endmodule
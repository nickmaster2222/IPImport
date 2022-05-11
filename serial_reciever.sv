`timescale 1ns / 1ps
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
    reg [7:0] din = 0;
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

    reg [15:0] clock_count = 0; //internal count to clock divide for proper baud rate and extra bit so it can be signed
    reg [7:0] shift_reg = 0;
    reg [2:0] data_pos = 0;
    reg [15:0] RX_count = 0;//will hace to go up to half of count_for_baud
    reg [31:0] rx_average = 0;

    enum {START_INCOMING='b001, DATA_INCOMING='b010, STOP_INCOMING='b100} current_state = START_INCOMING;
    always @(posedge clk) begin
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
					current_state <= START_INCOMING;
				end
            DATA_INCOMING: begin
                if(clock_count == count_for_baud) begin
                    clock_count <= 0;
                    if(data_pos == 7) begin //end of data reached
                        rx_average <= 0;//should help with ringing as it's measuring the average voltage instead of the voltage at one point in time
                        data_pos <= 0;
                        din <= {rx_average > count_for_baud / 2 ? 1 : 0, shift_reg[7:1]}; //shifts by one in proccess
                        wr_en <= 1;
						current_state <= STOP_INCOMING;
                    end else begin
                        rx_average <= 0;
                        shift_reg <= {rx_average > count_for_baud / 2 ? 1 : 0, shift_reg[7:1]};
                        data_pos <= data_pos + 1;
						current_state <= DATA_INCOMING;
						wr_en <= 0;
                    end
                end else begin
                    clock_count <= clock_count + 1;
                    rx_average <= rx_average + RX;
                end
            end
            STOP_INCOMING: begin
                wr_en <= 0;
                din <= 0;
                if(RX)//if already positive we don't need to wait
                    current_state <= START_INCOMING;
                shift_reg <= 0;
            end
			default: begin
                current_state <= START_INCOMING;
                din <= 0;
                shift_reg <= 0;
				clock_count <= 0;
				data_pos <= 0;
				wr_en <= 0;
				rx_average <= 0;
            end
        endcase
    end
endmodule

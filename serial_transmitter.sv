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




    reg [15:0] clock_count = count_for_baud; //internal count to clock divide for proper baud rate
    reg [7:0] shift_reg = 0;

    reg [2:0] shift_pos = 0;



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
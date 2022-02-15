`timescale 1ns / 1ps
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
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


//module serial_reciever(
//    input clk,
//    input RX,
//    output reg [7:0] recieved = 0,
//    output reg data_recieved, //goes high when data is recieved
//    input [16:0] count_for_baud_rate
//);

//    reg [9:0] shift_reg; //needs to be 10 bits long to catch all data and start/stop bits
//    wire bus_clock;
//    //clock_divider divider (clk, bus_clock, count_for_baud_rate, clock_sync);


//    reg start_incoming = 1; //start bit is incoming
//    reg [16:0] clock_count = 0;
//    reg [4:0] count = 0;
//    always@ (posedge clk) begin //recieving
//        data_recieved = 0;
//        if(RX == 0 && start_incoming) begin //set read time to halfway through signal period as this is the start bit
//            clock_count = count_for_baud_rate / 2;
//            start_incoming = 0;
//            count = 0;
//        end
//        if(clock_count == count_for_baud_rate) begin
//            clock_count = 0;
//            if(!start_incoming) begin //no incoming means already going
//                if(count == 9) begin
//                    start_incoming = 1;
//                    recieved = shift_reg[8:1]; //write in normal order
//                    shift_reg = 0;
//                    data_recieved = 1; //signal new byte is in buffer
//                end else begin
//                    shift_reg = shift_reg >> 1;
//                    shift_reg[9] = RX;
//                    count = count + 1;
//                end
//            end
//        end else begin
//            clock_count = clock_count + 1;
//        end
//    end

//    //not ideal way of handling this, for high throughput I should instead change this to a posedge clk sensitivity list and set something up so that I can use a sycronized method of clock synching
//    //    always@ (negedge RX) begin//syncs bus_clock everytime a start bit comes through
//    //        if(start_incoming) begin
//    //            clock_sync <= 1;//signal clock next clk
//    //        end else 
//    //            clock_sync = 0;
//    //    end    

//endmodule

module serial_reciever #(parameter CLK_IN=0, parameter BAUD=0)( //no in built FIFO as of yet
    input clk,
    input wire RX,
    input rd_en,
    output empty,
    output full,
    output [7:0] dout,
    output [11:0] data_count//,
    //input [15:0] count_for_baud //max clock division of 2^16 -1
);
    import types::*;
    parameter count_for_baud = CLK_IN / BAUD;
    
    reg srst = 0; //I don't use reset at the moment
    reg wr_en = 0;
    u8 din = 0;
    wire valid;
    uart_fifo fifo(
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
                if(RX_count == count_for_baud) begin //to decrease possible false positives, maybe remove
                    clock_count <= 0;
                    current_state <= DATA_INCOMING;
                    RX_count <= 0;
                end else if(!RX) begin //start bit detection to sync clock for rest of byte
                    RX_count <= RX_count + 1;
                end
            end
            DATA_INCOMING: begin
                if(clock_count == count_for_baud) begin
                    clock_count <= 0;

                    if(data_pos == 7) begin //end of data reached
                        current_state <= STOP_INCOMING;
                        rx_average <= 0;
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

//will not use double buffering for lesser memory requirements
//3 bits per pixel, not ideal packing however as I will only have a dual port ram so it will be done with 2 pixels in 8 bits
//addresses will be represented by two 10 bit numbers
//can be reconfigured at runtime though the actual memory buffer is fixed so the maximum size is decided by that
//there is also the 1024 x 1024 maximum imposed by the address bit sizes but I think that's ok for an FPGA
//srst MUST be held high for width * height clock cycles for a full clear
module vga #(BUF_WIDTH=640, BUF_HEIGHT=480) (
	input clk,
	input srst,
	input vclk,	//25.175 MHz video master clock for default 640 x 480 @60 Hz
	input [9:0] height,
	input [9:0] width,
	input [2:0] clear,		//clear color
	input [7:0] h_config [2:0],	//8 bits for front porch, sync pulse, and back porch, all in pixels
	input [7:0] v_config [2:0],	//the same but for vertical
	input [9:0] X,
	input [9:0] Y,
	input wr_en,
	input [2:0] pixel,
	output vsync,
	output hsync,
	output visible,	//if false pixels can be written without tearing as long as it's completed before this goes true
	output reg [2:0] RGB
)
	reg [2:0] vram [$clog2(BUF_HEIGHT - 1):0][$clog2(BUF_WIDTH / 2 - 1):0];//lets see if vivado can realize this should be a bram
	
	always @(posedge clk) begin
        
    end
	
	reg [10:0] x_pos;
	reg [10:0] y_pos;
	reg reseted;
	//need to account for blanking areas
	always @(posedge vclk) begin
        if(srst) begin//this outputs the clear color and clears vram
			RGB <= clear;
			reseted <= 1;
            x_pos <= x_pos == width - 1 ? 0 : x_pos + 1;
			y_pos <= y_pos == height - 1 ? 0 : y_pos + 1;
			vram[y_pos][x_pos] = clear;
        end else begin
            if(reseted) begin
                x_pos <= 0;
				y_pos <= 0;
            end
			if(x_pos < width - 1 && y_pos < height - 1) begin
                RGB <= vram[y_pos][x_pos];
            end else begin
                RGB <= 0;
				hsync <= x_pos >= width + h_config[0] && x_pos <= width + h_config[0] + h_config[1];
				if(x_pos == width + h_config[0] + h_config[1] + h_config[2]) begin
					x_pos <= 0;
					y_pos <= y_pos + 1;
				end
            end
        end
    end
	
endmodule
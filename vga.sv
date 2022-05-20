//will not use double buffering for lesser memory requirements
//3 bits per pixel, not ideal packing however as I will only have a dual port ram so it will be done with 2 pixels in 8 bits
//addresses will be represented by two 10 bit numbers
//can be reconfigured at runtime though the actual memory buffer is fixed so the maximum size is decided by that
//there is also the 1024 x 1024 maximum imposed by the address bit sizes but I think that's ok for an FPGA and this could be changed 
//srst MUST be held high for width * height clock cycles for a full clear
//default timings can be found at http://tinyvga.com/vga-timing/640x480@60Hz
//for faster performance I should make a version with most of the config parameterized so the synthesis tools can optimize for them being static
//for better performance and area usage I should figure out how to remove the multiplies 
//I might also have to move to using an explicit macro BRAM instead of an infered one
module vga #(BUF_WIDTH=640, BUF_HEIGHT=480) (
	input clk,
	input srst,
	input vclk,	//25.175 MHz video master clock for default 640 x 480 @60 Hz
	input [9:0] height,
	input [9:0] width,
	input [2:0] clear,		//clear color
	input [7:0] h_config [2:0],	//8 bits for front porch, sync pulse, and back porch, all in pixel counts
	input [7:0] v_config [2:0],	//the same but for vertical
	input [9:0] X,
	input [9:0] Y,
	input wr_en,
	input [2:0] pixel,
	output vsync,
	output hsync,
	output visible,	//if false pixels can be written without tearing as long as it's completed before this goes true
	output reg [2:0] RGB
);
	reg [2:0] vram [$clog2(BUF_HEIGHT - 1) * $clog2(BUF_WIDTH - 1):0];
	
	reg [10:0] x_pos;//bit width could be changed without issue I think
	reg [10:0] y_pos;//bit width could also be changed I think
	reg reseted;
	assign hsync = !(x_pos >= width + h_config[0] && x_pos < width + h_config[0] + h_config[1]);
	assign vsync = !(y_pos >= height + v_config[0] && y_pos < height + v_config[0] + v_config[1]);

	reg [2:0] reading;//used for bram infering
	
	always @(posedge clk) begin
	   if(wr_en && !srst)//if reset is being raised this won't write to vram
	       vram[Y][X] = pixel;
	   else if (srst)
	   		vram[y_pos * width + x_pos] <= clear;
	end
	
	always @(posedge vclk) begin
        if(srst) begin//this outputs the clear color and clears vram if held high for long enough
			RGB <= clear;
			reseted <= 1;
            x_pos <= x_pos == width - 1 ? 0 : x_pos + 1;
			y_pos <= y_pos == height - 1 ? 0 : y_pos + 1;
        end else begin
            if(reseted) begin
                x_pos <= '0;
				y_pos <= '0;
				reseted <= '0;
				RGB <= '0;
				reading <= vram[0];
            end else if(x_pos < width - 1 && y_pos < height - 1) begin//whether we're in the visible area
                reading <= vram[y_pos * width + x_pos];
				RGB <= reading;//need a delay on the read for proper bram infering
				x_pos <= x_pos + 1;
            end else begin
                RGB <= '0;
				if(x_pos == width + h_config[0] + h_config[1] + h_config[2] - 1) begin
					x_pos <= 0;
					y_pos <= y_pos == height + v_config[0] + v_config[1] + v_config[2] - 1 ? 0 : y_pos + 1;
					reading <= vram[(y_pos == height + v_config[0] + v_config[1] + v_config[2] - 1 ? 0 : y_pos + 1) * width];
				end else begin
                    x_pos <= x_pos + 1;
					y_pos <= y_pos;
					reading <= vram[y_pos * width + x_pos];
                end
            end
        end
    end
	
endmodule
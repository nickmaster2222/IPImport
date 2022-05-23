//will not use double buffering for lesser memory requirements
//addresses will be represented by two 10 bit numbers
//can be reconfigured at runtime though the you can't go beyond the physical maximums defined by bit widths
//there is also the 1024 x 1024 maximum imposed by the address bit sizes but I think that's ok for an FPGA and this could be changed 
//default timings can be found at http://tinyvga.com/vga-timing/640x480@60Hz
//for faster performance I should make a version with most of the config parameterized so the synthesis tools can optimize for them being static
//for better performance and area usage I should figure out how to remove the multiplies 
//this doesn't have an internal fram buffer, instead it sends memory requests to an external one and is always requesting
module vga #(BUF_WIDTH=640, BUF_HEIGHT=480) (
	input clk,
	input srst,
	input vclk,	//25.175 MHz video master clock for default 640 x 480 @60 Hz
	input [9:0] width,
	input [9:0] height,
	input [2:0] clear,		//clear color
	input [7:0] h_config [2:0],	//8 bits for front porch, sync pulse, and back porch, all in pixel counts
	input [7:0] v_config [2:0],	//the same but for vertical
	input [2:0] pixel,			//pixel request result
	output [19:0] req_addr,	//pixel address request
	output vsync,
	output hsync,
	output frame_start, //end of the visible area for this frame
	output frame_end,
	output visible,	//if false pixels can be written without tearing as long as it's completed before this goes true
	output reg [2:0] RGB
);	
	reg [9:0] x_pos;//bit width could be changed without issue I think
	reg [9:0] y_pos;//bit width could also be changed I think
	reg [19:0] read_pos;// equal to y_pos * width + x_pos but not quite since I don't add to it when not in the visible area
	assign req_addr = read_pos;
	assign hsync = !(x_pos >= width + h_config[0] && x_pos < width + h_config[0] + h_config[1]);
	assign vsync = !(y_pos >= height + v_config[0] && y_pos < height + v_config[0] + v_config[1]);
	assign visible = x_pos < width && y_pos < height;
	assign frame_end = x_pos == width && y_pos == height - 1;//signals once the frame is completely over
	assign frame_start = x_pos == 0 && y_pos == 0;
	
	always @(posedge vclk) begin
        if(srst) begin//this outputs the clear color while held and resets vars but the user will have to reset vram if they want that
			RGB <= clear;
            x_pos <= 0;
			y_pos <= 0;
			read_pos <= 0;
        end else begin 
			if(x_pos < width && y_pos < height) begin//whether we're in the visible area
				x_pos <= x_pos + 1;
				read_pos <= read_pos + 1;//only add to it while in the visible area
				RGB <= pixel;
            end else begin
				if(x_pos == width + h_config[0] + h_config[1] + h_config[2] - 1) begin//either next scanline or next frame
					x_pos <= 0;
					if(y_pos == height + v_config[0] + v_config[1] + v_config[2] - 1) begin	//next frame
						y_pos <= 0;
						read_pos <= 0;
						RGB <= pixel;
					end else begin	//next scanline
                        y_pos <= y_pos + 1;
						read_pos <= read_pos + 1;
						RGB <= pixel;
                    end
				end else begin//off of the visible area
                    x_pos <= x_pos + 1;
					y_pos <= y_pos;
					RGB <= 0';
                end
            end
        end
    end
	
endmodule
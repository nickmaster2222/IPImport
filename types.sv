`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/17/2022 12:07:54 AM
// Design Name: 
// Module Name: types
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

//ll of these are little endian
package types;//no idea what I'd do with some of these but may as well make them
typedef logic [0:0] u1;
typedef logic [1:0] u2;
typedef logic [2:0] u3;
typedef logic [3:0] u4;
typedef logic [4:0] u5;
typedef logic [5:0] u6;
typedef logic [6:0] u7;
typedef logic [7:0] u8;
typedef logic [8:0] u9;
typedef logic [9:0] u10;
typedef logic [10:0] u11;
typedef logic [11:0] u12;
typedef logic [12:0] u13;
typedef logic [13:0] u14;
typedef logic [14:0] u15;
typedef logic [15:0] u16;
typedef logic [23:0] u24;
typedef logic [31:0] u32;
typedef logic [35:0] u36;//odd sizes past 24 are for maximizing potential BRAM memory or potential multiples of it
typedef logic [63:0] u64;
typedef logic [71:0] u72;
typedef logic [127:0] u128;
typedef logic [143:0] u144;
typedef logic [255:0] u256;
typedef logic [287:0] u288;

typedef logic signed [0:0] i1;
typedef logic signed [1:0] i2;
typedef logic signed [2:0] i3;
typedef logic signed [3:0] i4;
typedef logic signed [4:0] i5;
typedef logic signed [5:0] i6;
typedef logic signed [6:0] i7;
typedef logic signed [7:0] i8;
typedef logic signed [8:0] i9;
typedef logic signed [9:0] i10;
typedef logic signed [10:0] i11;
typedef logic signed [11:0] i12;
typedef logic signed [12:0] i13;
typedef logic signed [13:0] i14;
typedef logic signed [14:0] i15;
typedef logic signed [15:0] i16;
typedef logic signed [23:0] i24;
typedef logic signed [31:0] i32;
typedef logic signed [35:0] i36;
typedef logic signed [63:0] i64;
typedef logic signed [72:0] i72;
typedef logic signed [127:0] i128;
typedef logic signed [143:0] i144;
typedef logic signed [255:0] i256;
typedef logic signed [287:0] i288;

endpackage

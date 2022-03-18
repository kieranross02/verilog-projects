//D-Flip-Flop (n-bits)
//sourced from professor's slides
module vDFFx(clk, in, out) ;
	parameter n = 1;  
	input clk ;
	input [n-1:0] in ;
	output [n-1:0] out ;
	reg [n-1:0] out ;

	always @(posedge clk)
		out <= in ;
endmodule

//register with load enable
module RLE(in,load,clk,out);
	input [15:0] in;
	input load, clk;
	output [15:0] out;

	reg [15:0] postMux;
	
	vDFFx #16 STORED(clk,postMux,out);
	
	//load-enabled multiplexer
	always @* begin
		case(load) 
			1'b0: postMux = out;
			1'b1: postMux = in;
			default: postMux = out;
		endcase
	end
endmodule

module decoder3_8(in,out);
	input [2:0] in;
	output [7:0] out;
	reg [7:0] out;
	
	always @* begin
		out=8'b00000000;
		case(in)
			3'b000: out[0] <= 1'b1;
			3'b001: out[1] <= 1'b1;
			3'b010: out[2] <= 1'b1;
			3'b011: out[3] <= 1'b1;
			3'b100: out[4] <= 1'b1;
			3'b101: out[5] <= 1'b1;
			3'b110: out[6] <= 1'b1;
			3'b111: out[7] <= 1'b1;
			default: out<=8'b00000000;
		endcase
	end
endmodule
	

module regfile(data_in,writenum,write,readnum,clk,data_out);
	input [15:0] data_in;
	input [2:0] writenum, readnum;
	input write, clk;
	output [15:0] data_out;
	reg [15:0] data_out;
	
	wire [7:0] selectwrite;
	wire [7:0] selectread;
	
	wire [15:0] R0;
	wire [15:0] R1;
	wire [15:0] R2;
	wire [15:0] R3;
	wire [15:0] R4;
	wire [15:0] R5;
	wire [15:0] R6;
	wire [15:0] R7;

	wire [7:0] rleIn;
	//converts binary writenum and readnum to onehot select
	decoder3_8 DECWRITE(writenum,selectwrite);
	decoder3_8 DECREAD(readnum,selectread);

	assign rleIn[0] = selectwrite[0]&write;
	assign rleIn[1] = selectwrite[1]&write;
	assign rleIn[2] = selectwrite[2]&write;
	assign rleIn[3] = selectwrite[3]&write;
	assign rleIn[4] = selectwrite[4]&write;
	assign rleIn[5] = selectwrite[5]&write;
	assign rleIn[6] = selectwrite[6]&write;
	assign rleIn[7] = selectwrite[7]&write;

	//stores register values on rising edge of clk based on one-hot load signal
	RLE r0(data_in,rleIn[0],clk,R0);
	RLE r1(data_in,rleIn[1],clk,R1);
	RLE r2(data_in,rleIn[2],clk,R2);
	RLE r3(data_in,rleIn[3],clk,R3);
	RLE r4(data_in,rleIn[4],clk,R4);
	RLE r5(data_in,rleIn[5],clk,R5);
	RLE r6(data_in,rleIn[6],clk,R6);
	RLE r7(data_in,rleIn[7],clk,R7);

	//outputs 16-bit data_out based on 8-bit one-hot selectread of register values
	always @* begin
		case(selectread) 
			8'b00000001: data_out = R0;
      			8'b00000010: data_out = R1;
     			8'b00000100: data_out = R2;
      			8'b00001000: data_out = R3;
      			8'b00010000: data_out = R4;
      			8'b00100000: data_out = R5;
      			8'b01000000: data_out = R6;
      			8'b10000000: data_out = R7;
			default: data_out = {16{1'bx}};
		endcase
	end
endmodule


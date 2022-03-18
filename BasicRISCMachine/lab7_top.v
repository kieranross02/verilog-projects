module lab7_top(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
	input [3:0] KEY;
	input [9:0] SW;
	output [9:0] LEDR;
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

	//RAM definitions
	`define MREAD 2'b00
	`define MNONE 2'b01
	`define MWRITE 2'b11
	
	//internal signals
	wire [1:0] mem_cmd;
	wire [8:0] mem_addr;
	wire [15:0] read_data, write_data, dout;
	
	reg mem_cmdread, mem_cmdwrite, msel, ldrsel, strsel;
	wire enable, enableldr, write, Z, N, V;
	
	//CPU instantiation
	cpu CPU(.clk   (~KEY[0]), 
         	.reset (~KEY[1]), 
       	 	.in    (read_data),
         	.out   (write_data),
         	.Z     (Z),
         	.N     (N),
         	.V     (V),
         	.mem_addr (mem_addr),
		.mem_cmd (mem_cmd) );
	
	//RAM instantiation
	RAM MEM(~KEY[0], mem_addr[7:0], mem_addr[7:0], write, write_data, dout);

	//tri-state driver
	assign read_data = enable ? dout : {16{1'bz}};
	assign read_data[7:0] = enableldr ? SW[7:0]: {8{1'bz}};
	assign read_data[15:8] = enableldr ? {8{1'b0}} : {8{1'bz}};
	assign enable = mem_cmdread&msel;
	assign write = mem_cmdwrite&msel;
	assign enableldr = mem_cmdread&ldrsel;
	assign loadstr = mem_cmdwrite&strsel;

	//LED str load-enabled D-FlipFlop
	LEvDFF #8 STRDFF(~KEY[0], loadstr, write_data[7:0], LEDR[7:0]);
	
	//Equality statements for RAM access
	always @* begin
		if(mem_cmd == `MREAD) mem_cmdread = 1'b1;
		else mem_cmdread = 1'b0;
		if(mem_cmd == `MWRITE) mem_cmdwrite = 1'b1;
		else mem_cmdwrite = 1'b0;
		if(mem_addr[8] == 1'b0) msel = 1'b1;
		else msel = 1'b0;
	end
	
	//LDR Switches Combinational Block
	always @* begin
		if(mem_addr == 9'h140) ldrsel = 1'b1;
		else ldrsel = 1'b0;
	end
	
	//STR LEDs Combinational Block
	always @* begin
		if(mem_addr == 9'h100) strsel = 1'b1;
		else strsel = 1'b0;
	end
	
	//assign states to HEX5 top, middle and bottom
	assign HEX5[0] = ~Z;
  	assign HEX5[6] = ~N;
  	assign HEX5[3] = ~V;
	assign HEX4 = 7'b1111111;
 	assign {HEX5[2:1],HEX5[5:4]} = 4'b1111; // disabled
	
	//assign output to first four seven-segment displays
	sseg H0(write_data[3:0],   HEX0);
  	sseg H1(write_data[7:4],   HEX1);
  	sseg H2(write_data[11:8],  HEX2);
  	sseg H3(write_data[15:12], HEX3);

endmodule

//Sourced from Slide-Set 11
module RAM(clk,read_address,write_address,write,din,dout);
	parameter data_width = 16; 
	parameter addr_width = 8;
	parameter filename = "data.txt";

	input clk;
	input [addr_width-1:0] read_address, write_address;
	input write;
	input [data_width-1:0] din;
	output [data_width-1:0] dout;
	reg [data_width-1:0] dout;

	reg [data_width-1:0] mem [2**addr_width-1:0];

	initial $readmemb(filename, mem);

	always @ (posedge clk) begin
		if (write)
			mem[write_address] <= din;
		dout <= mem[read_address]; // dout doesn't get din in this clock cycle 
                               // (this is due to Verilog non-blocking assignment "<=")
	end 
endmodule

module sseg(in,segs);
  	input [3:0] in;
  	output [6:0] segs;
  	reg [6:0] segs;
	always @* begin
		case(in)
                        4'b0000: segs = 7'b1000000; //0
                        4'b0001: segs = 7'b1111001; //1
                        4'b0010: segs = 7'b0100100; //2
                        4'b0011: segs = 7'b0110000; //3
                        4'b0100: segs = 7'b0011001; //4
                        4'b0101: segs = 7'b0010010; //5
                        4'b0110: segs = 7'b0000010; //6
                        4'b0111: segs = 7'b1111000; //7
                        4'b1000: segs = 7'b0000000; //8
                        4'b1001: segs = 7'b0011000; //9
			4'b1010: segs = 7'b0001000; //A
                        4'b1011: segs = 7'b0000011; //b
                        4'b1100: segs = 7'b1000110; //C
                        4'b1101: segs = 7'b0100001; //d
                        4'b1110: segs = 7'b0000110; //E
                        4'b1111: segs = 7'b0001110; //F
                        default : segs = 7'b0111111; //-
		endcase
  	end
endmodule

//Load-Enabled D-Flip-Flop (n-bits)
//sourced/edited from professor's slides
module LEvDFF(clk, load, in, out) ;
	parameter n = 1;  
	input clk, load ;
	input [n-1:0] in ;
	output [n-1:0] out ;
	reg [n-1:0] out ;
	wire [n-1:0] enabled_in;

	assign enabled_in = (load)?in:out;

	always @(posedge clk)
		out <= enabled_in ;
endmodule

module datapath(clk, readnum, vsel, loada, loadb, shift, asel, bsel, ALUop, loadc, loads, writenum, write, sximm8, sximm5, mdata, PC, Z_out, datapath_out, V_out, N_out);
	//outer variables
	input clk, loada, loadb, asel, bsel, loadc, loads, write;
	input [3:0] vsel;
	input [1:0] shift, ALUop;
	input [2:0] readnum, writenum;
	input [8:0] PC;
	input [15:0] mdata, sximm8, sximm5;
	output Z_out, V_out, N_out;
	output [15:0] datapath_out;

	//Lab 6 useless variables - tbd for Lab 7
	wire [15:0] PCin;
	assign PCin = {7'b0,PC};

	//inner variables
	reg [15:0] data_in;
	wire [15:0] data_out;
	wire [15:0] loaded_A;
	reg [15:0] Ain;
	wire [15:0] loaded_B;
	wire [15:0] sout;
	reg [15:0] Bin;
	wire [15:0] out;
	wire Z, V, N;

	//vsel MUX determining wether data_in is datapath_in or datapath_out
	always @* begin
		case(vsel)
			4'b0001: data_in = sximm8;
			4'b0010: data_in = datapath_out;
			4'b0100: data_in = PCin;
			4'b1000: data_in = mdata;
			default: data_in = 16'bxxxxxxxxxxxxxxxx;
		endcase
	end
	
	//determining data_out from register file
	regfile REGFILE(data_in,writenum,write,readnum,clk,data_out);
	
	//loadA load-enabled DFF
	LEvDFF #16 LOADA(clk,loada,data_out,loaded_A);
	
	//Ain MUX
	always @* begin
		case(asel)
			1'b0: Ain = loaded_A;
			default: Ain = {16{1'b0}};
		endcase
	end

	//loadB load-enabled DFF
	LEvDFF #16 LOADB(clk,loadb,data_out,loaded_B);
	
	//Shifter instantiation on loaded_B
	shifter SHIFT(loaded_B,shift,sout);
	
	//Bin MUX
	always @* begin
		case(bsel)
			1'b0: Bin = sout;
			default: Bin = sximm5;
		endcase
	end

	//ALU instantiation determining out
	ALU ALU_U2(Ain,Bin,ALUop,out,Z, V, N);

	//status load-enabled DFF
	LEvDFF LOADZ(clk,loads,Z,Z_out);
	LEvDFF LOADN(clk,loads,N,N_out);
	LEvDFF LOADV(clk,loads,V,V_out);
	

	//LoadC load-enabled DFF
	LEvDFF #16 LOADC(clk,loadc,out,datapath_out);


endmodule

module cpu(clk,reset,in,out,N,V,Z, mem_addr, mem_cmd);
	input clk, reset;
	input [15:0] in;
	output [15:0] out;
	output N, V, Z;
	output [8:0] mem_addr;
	output [1:0] mem_cmd;
	
	//State Encoding
	`define RST 4'b0000
	`define IF1 4'b0001
	`define IF2 4'b0010
	`define UPC 4'b0011
	`define D 4'b0100
	`define GB 4'b0101
	`define GA 4'b0110
	`define MOV 4'b0111
	`define ALU 4'b1000
	`define LDR 4'b1001
	`define Wi 4'b1010
	`define Wr 4'b1011
	`define IO 4'b1100
	`define H 4'b1101
	`define ADDi 4'b1110
	`define LOAD 4'b1111
	
	
	//RAM definitions
	`define MREAD 2'b00
	`define MNONE 2'b01
	`define MWRITE 2'b11

	wire [15:0] out;
	wire Z, V ,N;

	//internal variables
	reg [3:0] PresentState;
	reg [2:0] nsel;
	wire [2:0] rwnum, opcode;
	wire [15:0] loadedin;

	reg loada, loadb, asel, bsel, loadc, loads, write;
	wire [1:0] shift, ALUop, op;
	reg [3:0] vsel;
	wire [15:0] mdata, sximm8, sximm5;

	//added Lab 7 internal Variables
	reg load_ir, load_pc, reset_pc, addr_sel, load_addr;
	reg [8:0] next_pc, added_pc, mem_addr;
	wire [8:0] PC, address_selected;
	reg [1:0] mem_cmd;

	reg counter;
	
	assign mdata = in;
	
	//Instruction Register chooses whether to update loadedin based on load input
	LEvDFF #16 INSTREG(clk,load_ir,in,loadedin);
	//Instruction Decoder module instantiation breaks up loaded input into individually important parts
	InsDec INSTDEC(loadedin,nsel,ALUop,sximm5,sximm8,shift,rwnum,opcode,op);
	//Datapath instantiation
	datapath DP(clk,rwnum,vsel, loada, loadb, shift, asel, bsel, ALUop, loadc, loads, rwnum, write, sximm8, sximm5, mdata, PC, Z, out, V, N);
	
	//Program Counter
	LEvDFF #9 PCounter(clk,load_pc,next_pc,PC);
	
	//Data Address
	LEvDFF #9 DA(clk,load_addr, out[8:0], address_selected);
	
	//Reset PC MUX, adder logic, and Address_select MUX
	always @* begin
		//reset PC logic
		if(reset_pc) next_pc = {9{1'b0}};
		else next_pc = added_pc;
		
		//adder logic
		added_pc = PC + 9'b000000001;
	
		//addr_sel MUX
		if(addr_sel) mem_addr = PC;
		else mem_addr = address_selected;
	end

	
	//State Machine Sequential Always Block
	always @(posedge clk) begin
		//if reset pressed, go to RESET STATE
		if(reset) PresentState <= `RST;
		else begin
			case(PresentState) 
				//if in reset state, automatically go to 1st INSTR-FETCH STATE
				`RST: PresentState <= `IF1;

				//if in 1st instruction fetch state, automatically go to 2nd INSTR-FETCH STATE
				`IF1: PresentState <= `IF2;

				//if in 2nd instruction fetch state, automatically go to UPDATE PC STATE
				`IF2: PresentState <= `UPC;
		
				//if in update pc state, automatically go to DECODE STATE
				`UPC: PresentState <= `D;
				`D: 
				begin
				case(opcode)
					//if in an ALU command (a state that utilizes primarily the ALU, such as ADD, CMP, AND, etc)
					//go to GETB STATE
					3'b101: PresentState <= `GB;
			
					//if in LDR or STR command, go to GETA STATE
					3'b011: PresentState <= `GA;
					3'b100: PresentState <= `GA;

					//if in a MOV command, next state depends on 'op'
					3'b110:
					begin
					case(op)
						//if writing with sx_imm8, go to WRITE-IMMEDIATE STATE
						2'b10: PresentState <= `Wi;
						//if writing a reg to another reg, go to GETB STATE
						2'b00: PresentState <= `GB;
						default: PresentState <= `RST;
					endcase
					end
					//if in HALT command, go to HALT STATE
					3'b111: PresentState <= `H;
					default: PresentState <= `RST;
				endcase
				end
				`GB:
				begin
				case(opcode)
					//if in ALU command
					3'b101:
					begin
					case(ALUop)
						//if in MVN command, go straight to ALU STATE
						2'b11: PresentState <= `ALU;
						//if in any other ALU command, go to GETA STATE first
						default: PresentState <= `GA;
					endcase
					end
					//otherwise, you are in MOV-reg or STR command and both go to MOV STATE
					default: PresentState <= `MOV;
				endcase
				end
				`GA:
				begin
				case(opcode)
					//if in ALU command, go to ALU STATE
					3'b101: PresentState <=`ALU;
					//otherwise, you are in STR or LDR command, and go to ADD-IMMEDIATE STATE
					default: PresentState <= `ADDi;
				endcase
				end
				`ALU: 
				begin
				case(ALUop)
					//if in CMP command, skip WRITE-REG STATE, and go straight to 1st INSTR-FETCH STATE
					2'b01: PresentState <= `IF1;
					//otherwise, go to WRITE-REG STATE
					default: PresentState <= `Wr;
				endcase
				end
				`LOAD: 
				begin
				case(opcode)
					//if in LDR command, go to IO STATE
					3'b011: PresentState <= `IO;
					//if in STR command, go to GETB STATE
					default: PresentState <= `GB;
				endcase
				end
				//ADD-IMMEDIATE always goes to LOAD STATE
				`ADDi: PresentState <= `LOAD;
				`MOV:
				begin
				case(opcode)
					//if in STR command, go to IO STATE
					3'b100: PresentState <= `IO;
					//otherwise go to WRITE-REG STATE
					default: PresentState <= `Wr;
				endcase
				end
				`IO:
				begin
				case(opcode)
					//if in LDR command, go to LDR STATE 
					3'b011: PresentState <= `LDR;
					//if in STR command, go to INSTR-FETCH STATE
					default: PresentState <= `IF1;
				endcase
				//reset counter
				counter <= 1'b0;
				end
				//if in HALT STATE, remain in HALT STATE
				`H: PresentState <= `H;
				`LDR: 
				begin
				//if counter = 1, move to INSTR-FETCH STATE 
				if(counter) PresentState <= `IF1;
				//otherwise counter = 0, return back to LDR STATE (required extra clock in order to synchronize read_data & write data)
				else PresentState <= `LDR;
				//after in LDR STATE, increment counter
				counter <= 1'b1;
				end
				default: PresentState <= `IF1; //all remaining unstated states should go to info fetch 1
			endcase
		end
	end
				
	//Combinational Always block determining outputs			
	always @* begin
		nsel = 4'b0000;
		vsel = 3'b000;
		loada = 1'b0;
		loadb = 1'b0;
		asel = 1'b0;
		bsel = 1'b0;
		loadc = 1'b0;
		loads = 1'b0;
		write = 1'b0;
		
		reset_pc = 1'b0;
		load_pc = 1'b0;
		addr_sel = 1'b0;
		mem_cmd = `MNONE;
		load_ir = 1'b0;
		load_addr = 1'b0;
		
		case(PresentState)
			`RST:
				begin
				reset_pc = 1'b1;
				load_pc = 1'b1;
				
				end
			`IF1: 
				begin
				addr_sel = 1'b1;
				mem_cmd = `MREAD;
				end
			`IF2: 	
				begin
				load_ir = 1'b1;
				addr_sel = 1'b1;
				mem_cmd = `MREAD;
				end
			`UPC: 
				begin
				load_pc = 1'b1;
				end
			`D: load_pc = 1'b0;
			`GB: 
				begin
				loadb = 1'b1;
				if(opcode == 3'b100) nsel = 3'b010;
				else nsel = 3'b100;
				end
			`GA:
				begin
				loada = 1'b1;
				nsel = 3'b001;
				end
			`ALU: 
				begin
				if(op == 01) loads = 1'b1;
				else loadc = 1'b1;
				end
			`MOV: 
				begin
				asel = 1'b1;
				loadc = 1'b1;
				end
				
			`Wi:
				begin
				nsel = 3'b001;
				vsel = 4'b0001;
				write = 1'b1;
				end
			`Wr:
				begin
				nsel = 3'b010;
				vsel = 4'b0010;
				write = 1'b1;
				end
			`ADDi: 
				//Ain + sx_imm5 (used for STR & LDR)
				begin
				bsel = 1'b1;
				loadc = 1'b1;
				end
			`LOAD: 
				//Loads address of item to be LDR/STR
				begin
				load_addr = 1'b1;
				addr_sel = 1'b0;
				//mem_cmd = `MREAD;
				end
			`IO:
				//Checks to see if reading (LDR) or writing (STR)
				begin
				if(opcode == 3'b100) mem_cmd = `MWRITE;
				else mem_cmd = `MREAD;
				end
			`LDR: 
				begin
				//Places loaded item into Rd
				mem_cmd = `MREAD;
				vsel = 4'b1000;
				write = 1'b1;
				nsel = 3'b010;
				end
			`H: write = 1'b0; //placeholder since value doesn't matter
			
		
			default: write = 1'b0; //placeholder since value doesn't matter
		endcase
	end
endmodule

//Instruction Decoder
module InsDec(loadedin, nsel, ALUop, sximm5, sximm8, shift, rwnum, opcode, op);
	input [15:0] loadedin;
	input [2:0] nsel;
	output [1:0] ALUop, shift, op;
	output [2:0] rwnum, opcode;
	output [15:0] sximm5, sximm8;

	wire [15:0] sximm5, sximm8;
	reg [2:0] rwnum;
	
	//internal signals
	wire [7:0] imm8;
	wire [4:0] imm5;

	assign imm8 = loadedin[7:0];
	assign imm5 = loadedin[4:0];
	
	SignExtend IMMED8(imm8,sximm8);
	SignExtend #5 IMMED5(imm5,sximm5);
		
	assign ALUop = loadedin[12:11];
	assign shift = loadedin[4:3];
	assign opcode = loadedin[15:13];
	assign op = loadedin[12:11];

	//nsel multiplexer to determine which register is read/written
	always @* begin
		case(nsel)
			3'b001: rwnum = loadedin[10:8];
			3'b010: rwnum = loadedin[7:5];
			3'b100: rwnum = loadedin[2:0];
			default: rwnum = 3'bxxx;
		endcase
	end
endmodule

//Parameterized Sign-Extender module
module SignExtend(in,inextended);
	parameter n = 8;
	input [n-1:0] in;
	output [15:0] inextended;

	reg [15:0] inextended;
	reg N;

	//combinational always block determines whether to extend as positive number or two's complement negative
	always @* begin
		if(in[n-1]) N=1'b1;
		else N=1'b0;
		if(N) inextended = {{(16-n){1'b1}},in};
		else inextended = {{(16-n){1'b0}},in};
	end
endmodule
	

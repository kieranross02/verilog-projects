module lab3_top(SW,KEY,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
	input [9:0] SW;
	input [3:0] KEY;
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	//output [9:0] LEDR; // optional: use these outputs for debugging on your DE1-SoC
	
	//State encoding
	//successful entry states
	`define SG0 4'b0000
	`define SG1 4'b0001
	`define SG2 4'b0010
	`define SG3 4'b0011
	`define SG4 4'b0100
	`define SG5 4'b0101
	`define SGF 4'b0110
	
	//unsuccessful entry states
	`define SB0 4'b1000
	`define SB1 4'b1001
	`define SB2 4'b1010
	`define SB3 4'b1011
	`define SB4 4'b1100
	`define SBF 4'b1101

	//error state
	`define SE 4'b1111

	//Coding for 7-segment display
	`define HO 7'b1000000
	`define HP 7'b0001100
	`define HE 7'b0000110
	`define HN 7'b0101011
	`define HC 7'b1000110
	`define HL 7'b1000111
	`define HS 7'b0010010
	`define HD 7'b0100001
	`define HR 7'b0101111

	//Reg for use in always block
	reg [3:0] PresentState;
	reg [3:0] NextState;
	reg [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	reg [3:0] inputSW;

	//Negative logic for buttons
	wire clk = ~KEY[0];
	wire reset = ~KEY[3];

	//Type 2: state machine (Moore = only present state) synchronous always block
	always @(posedge clk) begin
		//if reset is being held down when clock is pressed, reset system fully
		if(reset) begin
			NextState = `SG0;
			
		end
		else begin
			//if input is larger than 9, send user to error state
			if(inputSW>4'b1001) begin
				NextState = `SE;
			end
			else begin
				//Coding NextStates based on PresentState and Inputs
				case(PresentState)
					`SG0: begin
							if(inputSW == 4'b0101) NextState = `SG1;
							else NextState = `SB0;
							end
					`SG1: begin
							if(inputSW == 4'b0101) NextState = `SG2;
							else NextState = `SB1;
							end
					`SG2: begin
							if(inputSW == 4'b0000) NextState = `SG3;
							else NextState = `SB2;
							end
					`SG3: begin
							if(inputSW == 4'b0010) NextState = `SG4;
							else NextState = `SB3;
							end
					`SG4: begin
							if(inputSW == 4'b0100) NextState = `SG5;
							else NextState = `SB4;
							end
					`SG5: begin
							if(inputSW == 4'b0101) NextState = `SGF;
							else NextState = `SBF;
							end
					`SGF: NextState = `SGF;
					`SB0: NextState = `SB1;
					`SB1: NextState = `SB2;
					`SB2: NextState = `SB3;
					`SB3: NextState = `SB4;
					`SB4: NextState = `SBF;
					`SBF: NextState = `SBF;
					`SE: NextState = `SE;
					default : NextState = `SG0; // Redundancy for the undefined state -> send to initial state (reset)
				endcase
			end
		end
		PresentState = NextState; // Update present state after case
	end

	//Type 1: Purely Combinational, use to set the output on 7-segment display
	always @* begin
		//setting input as only the first four switches, so we can ignore the other switches in the future
		inputSW <= SW[3:0];
		case(PresentState)
			//Successfully Opened State, assign 7-segment display = "OPEn"
			`SGF: begin
					HEX0 = `HN;
					HEX1 = `HE;
					HEX2 = `HP;
					HEX3 = `HO;
					HEX4 = 7'b1111111;
					HEX5 = 7'b1111111;
					end
			//Unsuccessfully Opened State, assign 7-segment display = "CLOSEd"
			`SBF: begin
					HEX0 = `HD;
					HEX1 = `HE;
					HEX2 = `HS;
					HEX3 = `HO;
					HEX4 = `HL;
					HEX5 = `HC;
					end
			//Binary Switches > 9, assign 7-segment display = "ErrOr"
			`SE:  begin
					HEX0 = `HR;
					HEX1 = `HO;
					HEX2 = `HR;
					HEX3 = `HR;
					HEX4 = `HE;
					HEX5 = 7'b1111111;
					end
			//<Number entered and display decimal>
			default: begin
					case(inputSW)
						4'b0000: HEX0 = 7'b1000000; //0
						4'b0001: HEX0 = 7'b1111001; //1
						4'b0010: HEX0 = 7'b0100100; //2
						4'b0011: HEX0 = 7'b0110000; //3
						4'b0100: HEX0 = 7'b0011001; //4
						4'b0101: HEX0 = 7'b0010010; //5
						4'b0110: HEX0 = 7'b0000010; //6
						4'b0111: HEX0 = 7'b1111000; //7
						4'b1000: HEX0 = 7'b0000000; //8
						4'b1001: HEX0 = 7'b0011000; //9
						default : HEX0 = 7'b0111111; //-
					endcase
					//None of the other displays are used so turn them off
					HEX1 = 7'b1111111;
					HEX2 = 7'b1111111;
					HEX3 = 7'b1111111;
					HEX4 = 7'b1111111;
					HEX5 = 7'b1111111;
				end
		endcase
	end
endmodule

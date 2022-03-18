`timescale 1 ps/ 1 ps
module lab3_top_tb ();

	reg [9:0] sim_SW;	
	reg [3:0] sim_KEY;
	wire [6:0] sim_HEX0, sim_HEX1, sim_HEX2, sim_HEX3, sim_HEX4, sim_HEX5;
	
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

	//unlock code = 550245
	lab3_top DUT (
		.SW(sim_SW),
		.KEY(~sim_KEY),
		.HEX0(sim_HEX0),
		.HEX1(sim_HEX1),
		.HEX2(sim_HEX2),
		.HEX3(sim_HEX3),
		.HEX4(sim_HEX4),
		.HEX5(sim_HEX5)
		);

	initial begin
		//reset system
		sim_KEY[0] = 1'b0;
		sim_KEY[3] = 1'b1;
		#1;
		sim_KEY[0] = 1'b1;
		#1
		//first test - opening lock: ideal situation
		sim_KEY[0] = 1'b0;
		sim_KEY[3] = 1'b0;

		//input 5
		sim_SW = 10'b0000000101; 
		#5;
		sim_KEY[0] = 1'b1;
		#1;
		sim_KEY[0] = 1'b0;

		//input 5
		sim_SW = 10'b0000000101;
		#5;
		sim_KEY[0] = 1'b1;
		#1;
		sim_KEY[0] = 1'b0;

		//input 0
		sim_SW = 10'b0000000000;
		#5;
		sim_KEY[0] = 1'b1;
		#1;
		sim_KEY[0] = 1'b0;

		//input 2
		sim_SW = 10'b0000000010;
		#5;
		sim_KEY[0] = 1'b1;
		#1;
		sim_KEY[0] = 1'b0;

		//input 4
		sim_SW = 10'b0000000100;
		#5;
		sim_KEY[0] = 1'b1;
		#1;
		sim_KEY[0] = 1'b0;

		//input 5
		sim_SW = 10'b0000000101;
		#5;
		sim_KEY[0] = 1'b1;
		#10
		
		$display("First Test: Perfect Outcome");
		$display("HEX0 output is: %b, should be %b", sim_HEX0, `HN);
		$display("HEX1 output is: %b, should be %b", sim_HEX1, `HE);
		$display("HEX2 output is: %b, should be %b", sim_HEX2, `HP);
		$display("HEX3 output is: %b, should be %b", sim_HEX3, `HO);
		$display(" ");

		
		
		//initial reset
		sim_KEY[0] = 1'b0;
		sim_KEY[3] = 1'b1;
		#1;
		sim_KEY[0] = 1'b1;
		#1
		//second test - mistake at first state
		sim_KEY[0] = 1'b0;
		sim_KEY[3] = 1'b0;


		//input 4 instead of 5
		sim_SW = 10'b0000000100; //testing to make sure additionaly switches do not play a part in process
		#5;
		sim_KEY[0] = 1'b1;
		#1;
		sim_KEY[0] = 1'b0;

		//input 5
		sim_SW = 10'b0000000101;
		#5;
		sim_KEY[0] = 1'b1;
		#1;
		sim_KEY[0] = 1'b0;

		//input 0
		sim_SW = 10'b0000000000;
		#5;
		sim_KEY[0] = 1'b1;
		#1;
		sim_KEY[0] = 1'b0;

		//input 2
		sim_SW = 10'b0000000010;
		#5;
		sim_KEY[0] = 1'b1;
		#1;
		sim_KEY[0] = 1'b0;

		//input 4
		sim_SW = 10'b0000000100;
		#5;
		sim_KEY[0] = 1'b1;
		#1;
		sim_KEY[0] = 1'b0;

		//input 5
		sim_SW = 10'b0000000101;
		#5;
		sim_KEY[0] = 1'b1;
		#10

		$display("Second Test: Failed Outcome");
		$display("HEX0 output is: %b, should be %b", sim_HEX0, `HD);
		$display("HEX1 output is: %b, should be %b", sim_HEX1, `HE);
		$display("HEX2 output is: %b, should be %b", sim_HEX2, `HS);
		$display("HEX3 output is: %b, should be %b", sim_HEX3, `HO);
		$display("HEX4 output is: %b, should be %b", sim_HEX4, `HL);
		$display("HEX5 output is: %b, should be %b", sim_HEX5, `HC);
		$display(" ");

		//initial reset
		sim_KEY[0] = 1'b0;
		sim_KEY[3] = 1'b1;
		#1;
		sim_KEY[0] = 1'b1;
		#1
		//third test - sent to error due to input above 9
		sim_KEY[0] = 1'b0;
		sim_KEY[3] = 1'b0;

		//input 10
		sim_SW = 10'b0000001010;
		#5;
		sim_KEY[0] = 1'b1;
		#10;

		$display("Third Test: Error Outcome");
		$display("HEX0 output is: %b, should be %b", sim_HEX0, `HR);
		$display("HEX1 output is: %b, should be %b", sim_HEX1, `HO);
		$display("HEX2 output is: %b, should be %b", sim_HEX2, `HR);
		$display("HEX3 output is: %b, should be %b", sim_HEX3, `HR);
		$display("HEX4 output is: %b, should be %b", sim_HEX4, `HE);

		$stop;
	end
endmodule

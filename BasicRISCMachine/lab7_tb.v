module lab7_tb();
	reg [3:0] KEY;
	reg [9:0] SW;
	wire [9:0] LEDR;
	wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	
	
	//DEVICE UNDER TEST (lab7_top) instantiation
	lab7_top DUT(~KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
	
	task clk;
	begin
	#1;
	KEY[0] = 1'b1;
	#1;
	KEY[0] = 1'b0;
	end
	endtask
	
	initial forever begin
    		clk();
  	end

	initial begin
		KEY[1] = 1'b1;
		#2;
		KEY[1] = 1'b0;

		#300;
		$stop;
	end
endmodule

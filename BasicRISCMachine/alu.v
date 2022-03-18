module ALU(Ain,Bin,ALUop,out,Z,V,N);
	input [15:0] Ain, Bin;
	input [1:0] ALUop;
	output [15:0] out;
	output Z, V, N;

	reg [15:0] out;
	reg Z, V, N;
	
	wire a, b, o;
	assign a = Ain[15];
	assign b = Bin[15];
	assign o = out[15];	

	always @* begin
		V = 1'b0;
		N = 1'b0;
		Z = 1'b0;
		case(ALUop)
			2'b00: out = Ain + Bin;
			2'b01: 
				begin
				out = Ain - Bin;
				N = out[15];
				if(a == ~b) begin
					if(b == o) V = 1'b1;
					else V = 1'b0;
				end
				else V = 1'b0;
				/*case(Ain[15])
					1'b1:
						case(Bin[15])
							1'b1:
								case(out[15])
									1'b0: V = 1'b1;
									default: V = 1'b0;
								endcase
							default: V = 1'b0;
						endcase
					default:
						case(Bin[15])
							1'b0:
								case(out[15])
									1'b1: V = 1'b1;
									default: V = 1'b0;
								endcase
							default: V = 1'b0;
						endcase
				endcase*/
				case(out)
					16'b0000000000000000: Z = 1'b1;
					default: Z = 1'b0;
				endcase
				end
			2'b10: out = Ain&Bin;
			2'b11: out = ~Bin;
			default: out = {16{1'bx}};
		endcase
	end
endmodule

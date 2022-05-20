module pwm_controller_tb;

logic motor_a, motor_b;
logic [7:0] period, duty;
logic [1:0] ctrl;
logic clk = 1; 
logic n_reset = 1;
pwm_controller u1(motor_a, motor_b, period, duty, ctrl, clk, n_reset);
int unsigned i;
int unsigned j;
always #50ps clk = ~clk;

initial begin
	period = 8'b00010100;
	duty = 8'b01111111;
	ctrl = 2'b01;

	for (j = 0; j < 4; j++) begin
		#10ps;
  		if(ctrl == 2'b00) begin
			#10ps;
			assert(motor_a == 0) $display("Correct"); else $display("error");
			assert(motor_b == 0) $display("Correct"); else $display("error");
			#10ps;
		end
		else if(ctrl == 2'b01) begin
			for (i = 0; i < period; i++) begin
				#10ps;
				if(i <= duty) begin
					assert(motor_a == 1) $display("Correct"); else $display("error");
					assert(motor_b == 0) $display("Correct"); else $display("error");
				
				end else begin
					assert(motor_a == 0) $display("Correct"); else $display("error");
					assert(motor_b == 0) $display("Correct"); else $display("error");
				end
			end
  		end 
		else if (ctrl == 2'b10) begin
			for (i = 0; i < period; i++) begin
				#10ps;
				if(i <= duty) begin
					assert(motor_a == 0) $display("Correct"); else $display("error");
					assert(motor_b == 1) $display("Correct"); else $display("error");
				end else begin
					assert(motor_a == 0) $display("Correct"); else $display("error");
					assert(motor_b == 0) $display("Correct"); else $display("error");
				end
			end
  		end 
		else begin
			#10ps;
			assert(motor_a == 1) $display("Correct"); else $display("error");
			assert(motor_b == 1) $display("Correct"); else $display("error");
			#10ps;
		end	
	end
end 

endmodule
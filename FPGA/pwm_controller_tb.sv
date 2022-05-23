module pwm_controller_tb;

logic motor_a, motor_b;
logic [7:0] period, duty;
logic brake = 1;
logic clockwise = 1;
logic power = 0;
logic clk = 1; 
logic n_reset = 1;

//instantiate PWM controller
pwm_controller u1(motor_a, motor_b, period, duty, clockwise, brake, power, clk, n_reset);

int periodCycles, dutyCycles;
int dutyPasses = 0;

always #50ps clk = ~clk;

initial begin
	period = 8'b00010100;
	duty = 8'b01111111;

	periodCycles = period * 5000;
	dutyCycles = duty * periodCycles / 255;

	@(posedge clk);
	#1ps assert({motor_a, motor_b} == 2'b00) $display("Power off Pass"); else $display("Power off Fail");

	power = 1;

	for (int i = 0; i < periodCycles; i++) begin
		@(posedge clk);
		#1ps;
		if(i <= dutyCycles) begin
			if(motor_a == 0 && motor_b == 1)
				dutyPasses++;
		end
		else begin
			if(motor_a == 0 && motor_b == 0)
				dutyPasses++;
		end
	end
	#1ps assert(dutyPasses == periodCycles) $display("Clockwise Pass"); else $display("Clockwise Fail");

	clockwise = 0;
	dutyPasses = 0;
	brake = 0;
	#1ps assert({motor_a, motor_b} == 2'b11) $display("Brake Pass"); else $display("Brake Fail");
	brake = 1;

	for (int i = 0; i < periodCycles; i++) begin
		@(posedge clk);
		#1ps;
		if(i <= dutyCycles) begin
			if(motor_a == 1 && motor_b == 0)
				dutyPasses++;
		end
		else begin
			if(motor_a == 0 && motor_b == 0)
				dutyPasses++;
		end
	end
	#1ps assert(dutyPasses == periodCycles) $display("Anti-Clockwise Pass"); else $display("Anti-Clockwise Fail");

	@(posedge clk);
	$stop;

end 

endmodule
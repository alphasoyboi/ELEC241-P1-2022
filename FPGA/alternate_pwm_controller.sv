module alternate_pwm_controller(output logic motor_1, motor_2, input logic [7:0] duty, period, input logic brake, clockwise, clk);

logic [7:0] counter = 0;
logic [7:0] scaled_duty;
logic motor_one, motor_two;

//delay is for testing purposes, should be removed once complete
assign #(10ps) {motor_1,motor_2} = {motor_one,motor_two};

always_ff @(posedge clk, negedge brake) begin
	scaled_duty = (duty * period) / 255;
	if(brake == 0) begin
		motor_one = 1'b1;
		motor_two = 1'b1;
	end
	else if(counter < period) begin
		if(counter <= scaled_duty) begin
			if(clockwise == 1'b1) begin
				motor_two = 1'b1;
				motor_one = 1'b0;
			end
			else begin
				motor_one = 1'b1;
				motor_two = 1'b0;
			end
		end
		else begin
			motor_one = 1'b0;
			motor_two = 1'b0;
		end
		counter++;
	end
	else begin
		if(counter <= scaled_duty) begin
			if(clockwise == 1'b1) begin
				motor_two = 1'b1;
				motor_one = 1'b0;
			end
			else begin
				motor_one = 1'b1;
				motor_two = 1'b0;
			end
		end
		else begin
			motor_one = 1'b0;
			motor_two = 1'b0;
		end
		counter = 0;
	end
end

endmodule
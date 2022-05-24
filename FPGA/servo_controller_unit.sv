module servo_controller_unit (
    output logic [31:0] status_reg,
    output logic [7:0] pwm_period, pwm_duty,
    output logic pwm_brake, pwm_power, clockwise,
    output logic atu_reset, atu_monitor, 
    input logic [31:0] input_reg, 
    input logic [11:0] current_angle, 
    input logic clk, n_reset
);

assign atu_monitor = 1;

logic [31:0] inputInternal;
logic [31:0] statusInternal = 0;
logic [11:0] desiredAngle;
logic [7:0] pwmPeriod, pwmDuty;
logic [1:0] controlMode, currentCommand, lastCommand;
logic power;
int clockwiseBounds, overflowBounds;
int propUpper, propLower, propOverUpper, propOverLower;

assign status_reg = statusInternal;
assign pwm_period = pwmPeriod;
assign pwm_duty = pwmDuty;
assign pwm_power = power;

always_ff @(posedge clk) begin
	inputInternal = input_reg;
	statusInternal[11:0] = current_angle;
	currentCommand = inputInternal[30:29];
	if(currentCommand == 2'b00 || currentCommand != lastCommand) begin
		desiredAngle = inputInternal[11:0];
		pwmPeriod = inputInternal[19:12];
		controlMode = inputInternal[28:27];
		power = inputInternal[31];
		if(currentCommand == 2'b10 || currentCommand == 2'b11)
			pwm_brake = 1;
		else
			pwm_brake = 0;
		if(currentCommand == 2'b01) begin
			for(int i = 0; i < 0; i++) begin
				if(i == 0)
					atu_reset = 0;
				else
					atu_reset = 1;
			end
		end
		
	end
	clockwiseBounds = desiredAngle + 503;
	overflowBounds = 0;
	if(clockwiseBounds > 1006) begin
		overflowBounds = clockwiseBounds - 1006;
		clockwiseBounds = 1006;
	end
	else begin
		if((current_angle > desiredAngle && current_angle < clockwiseBounds) || (current_angle < desiredAngle && current_angle < overflowBounds))
			clockwise = 0;
		else
			clockwise = 1;
		if(controlMode == 2'b00) begin
			if(current_angle == desiredAngle)
				pwmDuty = 8'd0;
			else
				pwmDuty = 8'd255;
		end
		else if(controlMode == 2'b01) begin
			propUpper = desiredAngle + 256;
			propLower = desiredAngle - 255;
			propOverUpper = 0;
			propOverLower = 1006;
			if(propUpper > 1006) begin
				propOverUpper = propUpper - 1006;
				propUpper = 1006;
			end
			else if(propLower < 0) begin
				propOverLower = propLower + 1006;
				propLower = 0;
			end
			if(current_angle > desiredAngle && current_angle < propUpper)
				pwmDuty = current_angle - desiredAngle;
			else if(current_angle < desiredAngle && current_angle < propOverUpper)
				pwmDuty = (8'd255 - propOverUpper) + current_angle;
			else if(current_angle > desiredAngle && current_angle >= propOverLower)
				pwmDuty = (current_angle - propOverLower) + desiredAngle;
			else if(current_angle < desiredAngle && current_angle >= propLower)
				pwmDuty = 8'd255 - (current_angle - propLower);
			else if(current_angle == desiredAngle)
				pwmDuty = 8'd0;
			else
				pwmDuty = 8'd255;
		end
	end
	lastCommand = currentCommand;
end

endmodule
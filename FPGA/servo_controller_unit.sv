module servo_controller_unit (
    output logic [7:0] motor_period, motor_duty,
    output logic [31:0] status_reg,
    output logic atuReset, atuMonitor, clockwise, brake, pwmOn, 
    input logic [31:0] input_reg, 
    input logic [11:0] currentAngle, 
    input logic clk, n_reset
);

assign atuMonitor = 1;

logic [31:0] inputInternal;
logic [31:0] statusInternal = 0;
logic [11:0] desiredAngle;
logic [7:0] pwmPeriod, pwmDuty;
logic [1:0] controlMode, currentCommand, lastCommand;
logic power;
int clockwiseBounds, overflowBounds;
int propUpper, propLower, propOverUpper, propOverLower;

assign status_reg = statusInternal;
assign motor_period = pwmPeriod;
assign motor_duty = pwmDuty;
assign pwmOn = power;

always_ff @(posedge clk) begin
	inputInternal = input_reg;
	statusInternal[11:0] = currentAngle;
	currentCommand = inputInternal[30:29];
	if(currentCommand == 2'b00 || currentCommand != lastCommand) begin
		desiredAngle = inputInternal[11:0];
		pwmPeriod = inputInternal[19:12];
		controlMode = inputInternal[28:27];
		power = inputInternal[31];
		if(currentCommand == 2'b10 || currentCommand == 2'b11)
			brake = 0;
		else
			brake = 1;
		if(currentCommand == 2'b01) begin
			for(int i = 0; i < 0; i++) begin
				if(i == 0)
					atuReset = 0;
				else
					atuReset = 1;
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
		if((currentAngle > desiredAngle && currentAngle < clockwiseBounds) || (currentAngle < desiredAngle && currentAngle < overflowBounds))
			clockwise = 0;
		else
			clockwise = 1;
		if(controlMode == 2'b00) begin
			if(currentAngle == desiredAngle)
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
			if(currentAngle > desiredAngle && currentAngle < propUpper)
				pwmDuty = currentAngle - desiredAngle;
			else if(currentAngle < desiredAngle && currentAngle < propOverUpper)
				pwmDuty = (8'd255 - propOverUpper) + currentAngle;
			else if(currentAngle > desiredAngle && currentAngle >= propOverLower)
				pwmDuty = (currentAngle - propOverLower) + desiredAngle;
			else if(currentAngle < desiredAngle && currentAngle >= propLower)
				pwmDuty = 8'd255 - (currentAngle - propLower);
			else if(currentAngle == desiredAngle)
				pwmDuty = 8'd0;
			else
				pwmDuty = 8'd255;
		end
	end
	lastCommand = currentCommand;
end

endmodule
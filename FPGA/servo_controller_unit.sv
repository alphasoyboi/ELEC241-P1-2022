module servo_controller_unit (
    output logic [7:0] motor_period, motor_duty, 
    output logic [1:0] motor_ctrl, 
    output logic [31:0] status_reg,
    output logic atuReset, atuMonitor, clockwise, brake, pwmOn, 
    input logic [31:0] input_reg, 
    input logic [11:0] currentAngle, 
    input logic clk, n_reset
);

assign motor_duty = 255;
assign motor_ctrl = 2'b10;
assign clockwise = 1;
assign atuMonitor = 1;
assign atuReset = 1;

logic [31:0] inputInternal;
logic [31:0] statusInternal = 0;

assign status_reg = statusInternal;

always_ff @(posedge clk) begin
	inputInternal = input_reg;
	statusInternal[11:0] = currentAngle;
	motor_period = inputInternal[19:12];
end

endmodule
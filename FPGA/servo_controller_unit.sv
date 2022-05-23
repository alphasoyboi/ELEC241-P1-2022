module servo_controller_unit (
    output logic [7:0] motor_period, motor_duty,
    output logic [31:0] status_reg,
    output logic atuReset, atuMonitor, clockwise, brake, pwmOn, 
    input logic [31:0] input_reg, 
    input logic [11:0] currentAngle, 
    input logic clk, n_reset
);

assign status_reg = input_reg;
assign motor_period = 20;
assign motor_duty = 255;
assign motor_ctrl = 0;

logic [31:0] inputInternal;
logic [31:0] statusInternal;

endmodule
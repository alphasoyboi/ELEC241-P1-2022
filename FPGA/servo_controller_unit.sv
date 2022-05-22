module servo_controller_unit (
    output logic [7:0] motor_period, motor_duty, 
    output logic [1:0] motor_ctrl, 
    output logic [31:0] status_reg, 
    output logic [11:0] display_angle, 
    output logic atuReset, atuMonitor, clockwise, brake, pwmOn, 
    input logic [31:0] input_reg, 
    input logic [11:0] currentAngle, 
    input logic clk, n_reset
);

assign display_angle = 12'd503;
assign motor_period = 20;
assign motor_duty = 255;
assign motor_ctrl = 0;

logic [31:0] inputInternal;
logic [31:0] statusInternal;

endmodule
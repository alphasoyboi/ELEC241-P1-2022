module servo_controller_unit (
    output logic [7:0] motor_period, motor_duty, 
    output logic [1:0] motor_ctrl, 
    output logic [31:0] status_reg,
    output logic atuReset, atuMonitor, clockwise, 
    input logic [31:0] input_reg, 
    input logic [11:0] currentAngle, 
    input logic clk, n_reset
);

// ctrl: 00 = off, 01 = clockwise, 10 = counter clockwise, 11 = brake

assign motor_duty = 50;
assign motor_ctrl = 2'b01;
assign clockwise = 1;
assign atuMonitor = 1;
assign atuReset = 1;
assign status_reg = currentAngle;

endmodule
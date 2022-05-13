module servo_controller_unit (
    output logic [11:0] angle, 
    output logic [7:0] motor_period, motor_duty, 
    output logic [1:0] motor_ctrl, 
    input logic clk, input logic n_reset
);

assign angle = 12'd1006;
assign motor_period = 50;
assign motor_duty = 255;
assign motor_ctrl = 2;

endmodule
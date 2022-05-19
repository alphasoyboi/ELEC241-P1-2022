module servo_controller_unit (
    output logic [7:0] motor_period, motor_duty, 
    output logic [1:0] motor_ctrl, 
    output logic [31:0] status_reg, 
	input logic [31:0] input_reg
);

assign angle = 12'd1006;
assign motor_period = 20;
assign motor_duty = 255;
assign motor_ctrl = 2;

endmodule
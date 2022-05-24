module servo_controller_unit_test (
    output logic [31:0] status_reg,
    output logic [7:0] pwm_period, pwm_duty,
    output logic pwm_brake, pwm_power, clockwise,
    output logic atu_reset, atu_monitor, 
    input logic [31:0] input_reg, 
    input logic [11:0] current_angle, 
    input logic clk, n_reset
);

assign pwm_duty = 255;
assign pwm_period = 20;
assign pwm_brake = 0;
assign pwm_power = 1;
assign clockwise = 1;
assign atu_monitor = 1;
assign atu_reset = 1;
assign status_reg = current_angle;

endmodule
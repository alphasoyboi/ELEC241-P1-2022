module pwm_controller(
    output logic motor_a,
    output logic motor_b, 
    input logic [7:0] duty, 
    input logic [7:0] period,
    input logic [3:0] ctrl);


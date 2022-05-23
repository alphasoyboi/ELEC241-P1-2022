module pwm_controller(
    output logic motor_a,
    output logic motor_b, 
    input logic [7:0] period,
	 input logic [7:0] duty, 
    input logic [1:0] ctrl,
    input logic clk,
    input logic n_reset
);

enum bit [1:0] {
	MOTOR_OFF   = 2'b00,
	MOTOR_CW    = 2'b01, // clockwise
	MOTOR_CCW   = 2'b10, // counter clockwise
	MOTOR_BRAKE = 2'b11
} motor_ctrl;

int unsigned clk_cnt, period_in_cycles, duty_in_cycles;

always_comb begin
    period_in_cycles = period * 5000;
    duty_in_cycles = duty * period_in_cycles / 255;
end

always_ff @(posedge clk or negedge n_reset) begin
    if (~n_reset)
        clk_cnt <= 0;
    else begin
        clk_cnt <= clk_cnt + 1;

        case (ctrl)
            MOTOR_OFF: begin
                {motor_a, motor_b} <= 2'b00;
            end
            MOTOR_CW: begin
                if (clk_cnt <= duty_in_cycles)
                    {motor_a, motor_b} <= 2'b10;
                else
                    {motor_a, motor_b} <= 2'b00;
                if (clk_cnt > period_in_cycles)
                    clk_cnt <= 0;
            end
            MOTOR_CCW: begin
                if (clk_cnt <= duty_in_cycles)
                    {motor_a, motor_b} <= 2'b01;
                else
                    {motor_a, motor_b} <= 2'b00;
                if (clk_cnt > period_in_cycles)
                    clk_cnt <= 0;
            end
            MOTOR_BRAKE: begin
                {motor_a, motor_b} <= 2'b11;
            end
        endcase
    end
end

endmodule
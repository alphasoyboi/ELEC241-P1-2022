module pwm_controller(
    output logic motor_a, motor_b, 
    input logic [7:0] period,
	input logic [7:0] duty, 
    input logic clockwise, brake, power, clk, n_reset
);

int unsigned clk_cnt, period_in_cycles, duty_in_cycles;

always_comb begin
    period_in_cycles = period * 5000;
    duty_in_cycles = duty * period_in_cycles / 255;
end

always_ff @(posedge clk, negedge n_reset, negedge brake) begin
    if (~n_reset)
        clk_cnt <= 0;
    else begin
        clk_cnt <= clk_cnt + 1;

	if(brake == 1'b0)
                {motor_a, motor_b} <= 2'b11;
	else if(power == 1'b0)
                {motor_a, motor_b} <= 2'b00;
        else if(clockwise == 1'b0) begin
                if (clk_cnt <= duty_in_cycles)
                    {motor_a, motor_b} <= 2'b10;
                else
                    {motor_a, motor_b} <= 2'b00;
                if (clk_cnt > period_in_cycles)
                    clk_cnt <= 0;
        end
	else if(clockwise == 1'b1) begin
                if (clk_cnt <= duty_in_cycles)
                    {motor_a, motor_b} <= 2'b01;
                else
                    {motor_a, motor_b} <= 2'b00;
                if (clk_cnt > period_in_cycles)
                    clk_cnt <= 0;
        end
    end
end

endmodule
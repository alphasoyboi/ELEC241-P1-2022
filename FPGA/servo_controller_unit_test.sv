module servo_controller_unit_test (
    output logic [31:0] status_reg,
    output logic [7:0] pwm_period, pwm_duty,
    output logic pwm_brake, pwm_power, clockwise,
    output logic atu_reset, atu_monitor, 
    input logic [31:0] input_reg, 
    input logic [11:0] current_angle, 
    input logic clk, n_reset
);

enum bit [1:0] {
    CTRL_BANG_BANG    = 2'b00,
    CTRL_PROPORTIONAL = 2'b01
} ctrl;

enum bit [1:0] {
    CMD_CONTINUOUS = 2'b00,
    CMD_RESET      = 2'b01,
    CMD_BRAKE      = 2'b11
} cmd;

bit [11:0] desired_angle;
bit [1:0] ctrl_mode;
bit [1:0] current_cmd, last_cmd; 
int clockwise_bounds, overflow_bounds;
int prop_upper, prop_lower, prop_over_upper, prop_over_lower;

assign pwm_period = 20;
assign pwm_brake  = 0;
assign pwm_power  = 1;
assign atu_reset = 1;

assign atu_monitor = 1;
assign status_reg = current_angle;
assign desired_angle = input_reg[11:0];

always_ff @(posedge clk or negedge n_reset) begin
    if (~n_reset) begin
        //pwm_duty   <= 0;
        //pwm_period <= 20;
        //pwm_brake  <= 0;
        //pwm_power  <= 1;

        //atu_reset <= 1;

        clockwise  <= 1;
    end
    else begin
        ctrl_mode <= input_reg[28:27];
        /*
        current_cmd = input_reg[30:29];
        if(current_cmd == CMD_CONTINUOUS || current_cmd != last_cmd) begin
            //desired_angle = input_reg[11:0];
            pwm_period <= input_reg[19:12];
            ctrl_mode <= input_reg[28:27];
            pwm_power <= input_reg[31];
            if(current_cmd == CMD_BRAKE)
                pwm_brake <= 1;
            else
                pwm_brake <= 0;
            if(current_cmd == CMD_RESET) begin
                for(int i = 0; i < 0; i++) begin
                    if(i == 0)
                        atu_reset <= 0;
                    else
                        atu_reset <= 1;
                end
            end
        end
        last_cmd <= current_cmd;
        */

        if (current_angle != desired_angle) begin
            clockwise_bounds <= desired_angle + 503;
            overflow_bounds <= 0;
            if(clockwise_bounds > 1006) begin
                overflow_bounds <= clockwise_bounds - 1006;
                clockwise_bounds <= 1006;
            end
            if((current_angle > desired_angle && current_angle < clockwise_bounds) || current_angle < overflow_bounds)
                clockwise <= 0;
            else 
                clockwise <= 1;
            if (ctrl_mode == CTRL_BANG_BANG) begin
					pwm_duty <= 255; 
            end
            else begin // proportional
                prop_upper = desired_angle + 256;
                prop_lower = desired_angle - 255;
                prop_over_upper = 0;
                prop_over_lower = 1006;
                if(prop_upper > 1006) begin
                    prop_over_upper = prop_upper - 1006;
                    prop_upper = 1006;
                end
                else if(prop_lower < 0) begin
                    prop_over_lower = prop_lower + 1006;
                    prop_lower = 0;
                end
                if(current_angle > desired_angle && current_angle < prop_upper)
                    pwm_duty = current_angle - desired_angle;
                else if(current_angle < desired_angle && current_angle < prop_over_upper)
                    pwm_duty = (8'd255 - prop_over_upper) + current_angle;
                else if(current_angle > desired_angle && current_angle >= prop_over_lower)
                    pwm_duty = (current_angle - prop_over_lower) + desired_angle;
                else if(current_angle < desired_angle && current_angle >= prop_lower)
                    pwm_duty = 8'd255 - (current_angle - prop_lower);
                else if(current_angle == desired_angle)
                    pwm_duty = 8'd0;
                else
                    pwm_duty = 8'd255;
            end
        end
        else
            pwm_duty <= 0;
    end
end

/*


*/
endmodule
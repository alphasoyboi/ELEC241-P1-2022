module angle_tracking_unit #(int unsigned cycles_debounce = 500) (
    output logic [11:0] angle, 
    input logic hall_1, hall_2, monitor, clockwise, 
    input logic clk, n_reset
);

//int unsigned clk_cnt;
bit hall_1_prev, hall_2_prev;

always_ff @(posedge clk or negedge n_reset) begin
    if (~n_reset) begin
        angle <= 0;
        hall_1_prev <= hall_1;
        hall_2_prev <= hall_2;
    end
    else begin
        if (monitor) begin
            if (clockwise) begin
                if ((hall_1 == 1 && hall_1_prev == 1) && hall_2 != hall_2_prev) begin
                    if (angle > 1006)
                        angle <= 0;
                    else
                        angle <= angle + 1;
                end
            end
            else begin
                if ((hall_2 == 1 && hall_2_prev == 1) && hall_1 != hall_1_prev) begin
                    if (angle == 0)
                        angle <= 1006;
                    else 
                        angle <= angle - 1;
                end
            end
				
            hall_1_prev = hall_1;
            hall_2_prev = hall_2;
        end
    end
end

endmodule
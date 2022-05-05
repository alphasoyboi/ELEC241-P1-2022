module atu_tb;

//internal signals
logic CLK = 0;
logic hall_1 = 0;
logic hall_2 = 0;
logic reset, monitor, clockwise;
logic [11:0] angle;
logic [1:0] counter = 2'd0;

//instantiate ATU
angle_tracking_unit u1(angle, hall_1, hall_2, reset, monitor, clockwise);

always #50ps CLK = ~CLK;

always_ff @(posedge CLK) begin
	if(clockwise == 1'b1) begin
		if(counter == 2'd0) begin
			hall_2 = ~hall_2;
			counter++;
		end
		else if(counter == 2'd3) begin
			hall_1 = ~hall_1;
			counter = 2'd0;
		end
		else
			counter++;
	end
	else begin
		if(counter == 2'd0) begin
			hall_1 = ~hall_1;
			counter++;
		end
		else if(counter == 2'd3) begin
			hall_2 = ~hall_2;
			counter = 2'd0;
		end
		else
			counter++;
	end
end

endmodule
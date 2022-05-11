module angle_tracking_unit #(parameter N = 12'd0) (output logic [11:0] angle, input logic hall_1, hall_2, n_reset, monitor, clockwise);

logic [11:0] starter = N;
logic [11:0] data = N;

//delay is for testing purposes, should be removed once complete
//assign #(10ps) angle = data;
assign angle = data;

//runs when hall 2 goes high, checks for clockwise
//also holds reset code
always_ff @(posedge hall_2, negedge n_reset) begin
	if(n_reset == 1'b0)
		starter = 12'd0;
	else if(clockwise == 1'b1 && monitor == 1'b1) begin
		if(hall_1 == 1'b1) begin
			data = starter + 12'd4;
			//overflow calculator. 4024 is the largest multiple of 1006 in 12 bits
			if(data == 12'd4024)
				data = 12'd0;
			starter = data;
		end
	end
end

//runs when hall 1 goes high, checks for anticlockwise
always_ff @(posedge hall_1) begin
	if(clockwise == 1'b0) begin
		if(hall_2 == 1'b1 && monitor == 1'b1) begin
			//reverse overflow calculator
			if(starter == 0)
				data = 12'd4020;
			else
				data = starter - 12'd4;
			starter = data;
		end
	end
end

endmodule
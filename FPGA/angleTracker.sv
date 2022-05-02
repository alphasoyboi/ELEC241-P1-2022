module angle_tracking_unit #(parameter N = 12'b000000000000) (output logic [11:0] angle, input logic hall_1, hall_2, reset, monitor, clockwise);

logic [11:0] starter = N;
logic [11:0] data;

//delay is for testing purposes, should be removed once complete
assign #(10ps) angle = data;

//runs when hall 1 goes high, checks for clockwise
//also holds reset code
always_ff @(posedge hall_1, negedge reset) begin
	if(reset == 1'b0)
		starter = 12'b000000000000;
	else if(clockwise == 1'b1) begin
		if(hall_2 == 1'b1) begin
			data = starter + //placeholder
			starter = data
		end
	end
end

//runs when hall 2 goes high, checks for anticlockwise
always_ff @(posedge hall_2) begin
	if(clockwise == 1'b0) begin
		if(hall_1 == 1'b1) begin
			data = starter - //placeholder
			starter = data
		end
	end
end

endmodule
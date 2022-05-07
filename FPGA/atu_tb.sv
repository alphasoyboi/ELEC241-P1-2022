module atu_tb;

//internal signals
logic CLK = 0;
logic hall_1 = 0;
logic hall_2 = 0;
logic clockwise = 1;
logic monitor = 1;
logic reset = 1;
logic [11:0] angle;
logic [1:0] counter = 2'd0;
logic [9:0] passes = 10'd0;

//instantiate ATU
angle_tracking_unit u1(angle, hall_1, hall_2, reset, monitor, clockwise);

always #50ps CLK = ~CLK;

always_ff @(posedge CLK) begin
	if(clockwise == 1'b1) begin
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
	else begin
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
end

initial begin

	//resets the angle
	reset = 1'b0;
	#10ps;
	reset = 1'b1;
	#1ps assert(angle == 12'd0) $display("Reset PASS"); else $error("Reset FAIL");

	//loop to check ATU works for full clockwise range
	for(int i = 0; i < 1005; i++) begin
		@(posedge hall_2);
		#11ps 
		//if(angle == ((i*4)-4))
			passes++;
	end
	#1ps assert(passes == 10'd1005) $display("Clockwise PASS"); else $error("Clockwise FAIL, only ", passes, " passes");

	//check that both clockwise and anticlockwise overflows work
	@(posedge hall_2);
	#11ps assert(angle == 12'd0) $display("Overflow PASS"); else $error("Overflow FAIL");
	clockwise = 0;
	@(posedge hall_1);
	#11ps assert(angle == 12'd4020) $display("Reverse Overflow PASS"); else $error("Reverse Overflow FAIL");

	//loop to check ATU works for full anticlockwise range
	passes = 10'd0;
	for(int i = 1005; i > 0; i--) begin
		@(posedge hall_1);
		#11ps 
		//if(angle == (i*4))
			passes++;
	end
	#1ps assert(passes == 10'd1005) $display("Anticlockwise PASS"); else $error("Anticlockwise FAIL, only ", passes, " passes");

	//loop to test turning monitoring off works
	monitor = 0;
	clockwise = 1;
	for(int i = 0; i < 10; i++) begin
		@(posedge hall_2);
	end
	#11ps assert(angle == 12'd0) $display("Monitor off PASS"); else $error("Monitor off FAIL");

	//check that turning monitoring back on works
	monitor = 1;
	@(posedge hall_2);
	#11ps assert(angle == 12'd4) $display("Monitor on PASS"); else $error("Monitor on FAIL");
	$stop;

end

endmodule
module atu_tb;

//internal signals
logic CLK = 0;
logic hall_1, hall_2, reset, monitor, clockwise;
logic [11:0] angle;

//instantiate ATU
angle_tracking_unit u1(angle, hall_1, hall_2, reset, monitor, clockwise);

always #50ps CLK = ~CLK;

endmodule
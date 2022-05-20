module IC_tb;

logic CLK = 0;
logic readBusy = 0;
logic writeBusy = 0;
logic [15:0] spi, outgoingData;
logic [31:0] statusReg = 0;
logic [31:0] incomingData;

interface_controller u1(outgoingData, incomingData, statusReg, spi, readBusy, writeBusy, CLK);

always #50ps CLK = ~CLK;

initial begin

	@(negedge CLK);
	readBusy = 1'b1;
	spi = {4'd2, 12'b001101000011};
	@(posedge CLK);
	#11ps assert(incomingData == 32'b0_00_00_0000000_00000000_000000000000) $display("Read Busy PASS"); else $error("Read Busy FAIL");
	@(negedge CLK);
	readBusy = 1'b0;
	#11ps assert(incomingData == 32'b0_00_00_0000000_00000000_001101000011) $display("Read not Busy/Angle Change PASS"); else $error("Read not Busy/Angle Change FAIL");
	@(negedge CLK);
	writeBusy = 1'b1;
	statusReg = 32'b00000000000000000000_001101000011;
	@(posedge CLK);
	#11ps assert(outgoingData == 16'b0000_000000000000) $display("Write Busy PASS"); else $error("Write Busy FAIL");
	@(negedge CLK);
	writeBusy = 1'b0;
	@(posedge CLK);
	#11ps assert(outgoingData == 16'b0000_001101000011) $display("Write not Busy PASS"); else $error("Write not Busy FAIL");
	@(negedge CLK);
	readBusy = 1'b1;
	spi = {4'd3, 12'b001101000011};
	@(posedge CLK);
	@(negedge CLK);
	readBusy = 1'b0;
	#11ps assert(incomingData == 32'b0_00_00_0000000_01000011_001101000011) $display("Period Change PASS"); else $error("Period Change FAIL");
	@(negedge CLK);
	readBusy = 1'b1;
	spi = {4'd4, 12'b001101000011};
	@(posedge CLK);
	@(negedge CLK);
	readBusy = 1'b0;
	#11ps assert(incomingData == 32'b0_00_11_0000000_01000011_001101000011) $display("Control Mode Change PASS"); else $error("Control Mode Change FAIL");
	@(negedge CLK);
	readBusy = 1'b1;
	spi = {4'd5, 12'b001101000010};
	@(posedge CLK);
	@(negedge CLK);
	readBusy = 1'b0;
	#11ps assert(incomingData == 32'b0_10_11_0000000_01000011_001101000011) $display("Command Change PASS"); else $error("Command Change FAIL");
	@(negedge CLK);
	readBusy = 1'b1;
	spi = {4'd6, 12'b001101000011};
	@(posedge CLK);
	@(negedge CLK);
	readBusy = 1'b0;
	#11ps assert(incomingData == 32'b1_10_11_0000000_01000011_001101000011) $display("Power Change PASS"); else $error("Power Change FAIL");
	#100ps;
	$stop;

end

endmodule
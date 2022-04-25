You must perform the following in the order specified.

1. Disconnect your ribbon cable from the Nucleo board
2. Drag and drop MCU.bin to the nucleo
3. Connect the ribbon cable to the Nucleo
4. Run the Quartus Programmer (quartus_pgmw.exe). Program the sof file to your FPGA
5. Every 10 seconds, the motor should rotate 180 degrees, alternating direction

If not, check the connections and solder joints on the h-bridge circuitry.


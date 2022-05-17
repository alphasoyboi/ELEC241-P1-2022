#include "uop_msb.h"
#include "elec241.h"

DigitalIn DO_NOT_USE(PB_12); // This Pin is connected to the 5VDC from the FPGA card and an INPUT that is 5V Tolerant

// serial peripheral interface (SPI)
SPI spi(PA_7, PA_6, PA_5); // mosi, miso, sclk
DigitalOut cs(PC_6);       // chip select

// buffered serial for terminal connection
static BufferedSerial serial_port(USBTX, USBRX);
// module support board buttons a & b
InterruptIn button_a(PG_0), button_b(PG_1);


uint16_t spi_readwrite(uint16_t data);


int main() {
    serial_port.set_baud(9600);
    serial_port.set_format(
        /* bits */     8,
        /* parity */   SerialBase::None,
        /* stop bit */ 1
    );
    // turn off blocking read/writes
    serial_port.set_blocking(false);

    //SET UP THE SPI INTERFACE
    cs = 1;                     // Chip must be deselected, Chip Select is active LOW
    spi.format(16,0);           // Setup the DATA frame SPI for 16 bit wide word, Clock Polarity 0 and Clock Phase 0 (0)
    spi.frequency(1000000);     // 1MHz clock rate
    wait_us(10000);

    // This will hold the 16-bit data returned from the SPI interface (sent by the FPGA)
    // Currently the inputs to the SPI recieve are left floating (see quartus files)
    uint16_t rx;

    while(true)                 
    {
        rx = spi_readwrite(0x00AA);     // Send binary 0000 0000 1010 1010
        printf("Recieved: %u\n",rx);    // Display the value returned by the FPGA
        wait_us(1000000);               // 
        rx = spi_readwrite(0x0055);     // Send binary 0000 0000 0101 0101
        printf("Recieved: %u\n",rx);    // Display the value returned by the FPGA
        wait_us(1000000);               //
    }
}

// **********************************************************************************************************
// uint16_t spi_readwrite(uint16_t data)
//
// Function for writing to the SPI with the correct timing
// data - this parameter is the data to be sent from the MCU to the FPGA over the SPI interface (via MOSI)
// return data - the data returned from the FPGA to the MCU over the SPI interface (via MISO)
// **********************************************************************************************************

uint16_t spi_readwrite(uint16_t data) {	
	cs = 0;             									//Select the device by seting chip select LOW
	uint16_t rx = (uint16_t)spi.write(data);				//Send the data - ignore the return data
	wait_us(1);													//wait for last clock cycle to clear
	cs = 1;             									//De-Select the device by seting chip select HIGH
	wait_us(1);
	return rx;
}
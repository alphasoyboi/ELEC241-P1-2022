#include "uop_msb.h"
#include "elec241.h"
#include <string>
//#include <cstring>

DigitalIn DO_NOT_USE(PB_12); // This Pin is connected to the 5VDC from the FPGA card and an INPUT that is 5V Tolerant

// serial peripheral interface (SPI)
SPI spi(PA_7, PA_6, PA_5); // mosi, miso, sclk
DigitalOut cs(PC_6);       // chip select

// buffered serial for terminal connection
static BufferedSerial serial_port(USBTX, USBRX);
// module support board buttons a & b
static InterruptIn button_a(PG_0), button_b(PG_1);

uint16_t spi_readwrite(uint16_t data);

typedef enum {
    READ_CMD,
    PROC_CMD
} TermState;

static const char *help_msg = R"(
commands:
    help   [angle|period|ctrl|cmd|power]
    angle  [0..360]
    period [0..255]
    ctrl   [bang|prop]
    cmd    [cont|zero|brake]
    power  [on|off]

)";
/*static const char *help_msg = R"(
    angle  [0-360]           - set servo angle (degrees)
    period [0-255]           - set pwm period (255 = 0.0255 seconds)
    ctrl   [bang|prop]       - set control mode [bang-bang|proportional]
    cmd    [cont|zero|brake] - send command [toggle continuous mode|reset zero angle|toggle brake]
    power  [on|off]          - set pwm power
)";*/
static const char *inv_cmd_msg = "invalid command (type help for commands and values)\n";
static const char *inv_val_msg = "inavlid value (type help for commands and values)\n";


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

    TermState term_state = READ_CMD;
    char c = 0;
    std::string buf;
    serial_port.write(help_msg, strlen(help_msg));
    while(true)                 
    {    
        switch (term_state) {
            case READ_CMD: {
                if (serial_port.read(&c, 1) != -EAGAIN) {
                    serial_port.write(&c, 1);
                    if (c == '\r') {
                        c = '\n';
                        serial_port.write(&c, 1);
                        c = 0;
                        term_state = PROC_CMD;
                    } else if (c) {
                        buf += c;
                    }
                }
                break;
            }
            case PROC_CMD: {
                if (buf.find("help") == 0) {
                    serial_port.write(help_msg, strlen(help_msg));
                } 
                else if (buf.find("angle") == 0) {
                    int angle = -1;
                    angle = stoi(buf.substr(buf.find_first_of(" ") + 1));
                    if (angle < 0 || angle > 360)
                        serial_port.write(inv_val_msg, strlen(inv_val_msg));
                }
                else if (buf.find("period") == 0) {
                    int period = -1;
                    period = stoi(buf.substr(buf.find_first_of(" ") + 1));
                    if (period < 0 || period > 255)
                        serial_port.write(inv_val_msg, strlen(inv_val_msg));
                }
                else if (buf.find("ctrl") == 0) {
                    
                }
                else {
                    serial_port.write(inv_cmd_msg, strlen(inv_cmd_msg));
                }

                buf.erase();
                term_state = READ_CMD;
                break;
            }
            default:
                term_state = READ_CMD;
        }

        /*
        rx = spi_readwrite(0x00AA);     // Send binary 0000 0000 1010 1010
        printf("Recieved: %u\n",rx);    // Display the value returned by the FPGA
        wait_us(1000000);               // 
        rx = spi_readwrite(0x0055);     // Send binary 0000 0000 0101 0101
        printf("Recieved: %u\n",rx);    // Display the value returned by the FPGA
        wait_us(1000000);               //
        */
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
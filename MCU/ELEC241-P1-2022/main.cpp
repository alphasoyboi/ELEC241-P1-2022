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
DigitalOut tx_led(LED1);

typedef enum {
    INIT,
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
static const char *inv_cmd_msg = "\ninvalid command (type help for commands and arguments)\n";
static const char *inv_arg_msg = "\ninavlid value (type help for commands and arguments)\n";

uint16_t spi_readwrite(uint16_t data);
TermState term_read(TermState state);

int main() {
    //SET UP THE SPI INTERFACE
    cs = 1;                     // Chip must be deselected, Chip Select is active LOW
    spi.format(16,0);           // Setup the DATA frame SPI for 16 bit wide word, Clock Polarity 0 and Clock Phase 0 (0)
    spi.frequency(1000000);     // 1MHz clock rate
    wait_us(10000);
    // This will hold the 16-bit data returned from the SPI interface (sent by the FPGA)
    // Currently the inputs to the SPI recieve are left floating (see quartus files)
    uint16_t rx;
    uint16_t tx;

    // set up terminal interface
    serial_port.set_baud(9600);
    serial_port.set_format(
        /* bits */     8,
        /* parity */   SerialBase::None,
        /* stop bit */ 1
    );
    // turn off blocking read/writes
    serial_port.set_blocking(false);

    int target_angle = 0, new_target_angle = 0;

    // assign interrupts
    button_a.rise([&new_target_angle](){
        ++new_target_angle;
        if (new_target_angle > 360)
            new_target_angle = 0;
    });
    button_b.rise([&new_target_angle](){
        --new_target_angle;
        if (new_target_angle < 0)
            new_target_angle = 360;
    });

    
    TermState term_state = INIT;
    serial_port.write(help_msg, strlen(help_msg));
    while(true)                 
    {    
        term_state = term_read(term_state);
        if (target_angle != new_target_angle) {
            target_angle = new_target_angle;
            tx = ANGLE << 12;
            tx += target_angle;
            rx = spi_readwrite(tx);
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

TermState term_read(TermState state)
{
    char c = 0;
    static size_t i = 0;
    constexpr size_t BUF_LEN = 64;
    static char buf[BUF_LEN];

    switch (state) {
        case READ_CMD: {
            if (serial_port.read(&c, 1) != -EAGAIN) {
                serial_port.write(&c, 1);
                if (c == '\r' || i >= BUF_LEN) {
                    i = 0;
                    buf[BUF_LEN - 1] = '\0';
                    state = PROC_CMD;
                } else if (c) {
                    buf[i++] = c;
                }
            break;
        }
        case PROC_CMD: {
            char *p = nullptr;
            if ((p = strstr(buf, "help")) == buf) {
                serial_port.write(help_msg, strlen(help_msg));
            } 
            else if ((p = strstr(buf, "angle")) == buf) {
                int angle = -1;
                if ((p = strchr(buf, ' ')))
                    angle = atoi(p);
                if (angle < 0 || angle > 360)
                    serial_port.write(inv_arg_msg, strlen(inv_arg_msg));
            }
            else if ((p = strstr(buf, "period")) == buf) {
                int period = -1;
                if((p = strchr(buf, ' ')))
                    period = atoi(p);
                if (period < 0 || period > 255)
                        serial_port.write(inv_arg_msg, strlen(inv_arg_msg));
            }
            else {
                serial_port.write(inv_cmd_msg, strlen(inv_cmd_msg));
            }

            memset(buf, '\0', BUF_LEN - 1);
            state = READ_CMD;
            break;
        }
        default: {
            memset(buf, '\0', BUF_LEN - 1);
            state = READ_CMD;
        }
    }
    return state;
}
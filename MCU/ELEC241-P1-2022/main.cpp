#include "uop_msb.h"
#include "elec241.h"
#include <algorithm>
#include <string>

DigitalIn DO_NOT_USE(PB_12); // This Pin is connected to the 5VDC from the FPGA card and an INPUT that is 5V Tolerant

// serial peripheral interface (SPI)
SPI spi(PA_7, PA_6, PA_5); // mosi, miso, sclk
DigitalOut cs(PC_6);       // chip select

// buffered serial for terminal connection
static BufferedSerial serial_port(USBTX, USBRX);
// module support board buttons a & b
static InterruptIn button_a(PG_0), button_b(PG_1);
DigitalOut tx_led(LED1);

static const char *help_msg = R"(
commands:
    help   [angle|period|ctrl|cmd|power]
    angle  [0..360]
    period [0..255]
    ctrl   [bang|prop]
    cmd    [cont|zero|brake]
    power  [on|off]
    status (display current servo angle)

)";
static const char *help_msg_angle  = "\nangle [0..360] - set servo angle (degrees)\n";
static const char *help_msg_period = "\nperiod [0..255] - set pwm period (255 = 0.0255 seconds)\n";
static const char *help_msg_ctrl   = "\nctrl [bang|prop] - set control mode (bang-bang, proportional)\n";
static const char *help_msg_cmd    = "\ncmd [cont|zero|brake] - send command (toggle continuous mode, reset zero angle, toggle brake)\n";
static const char *help_msg_power  = "\npower [on|off] - set pwm power\n";
static const char *inv_cmd_msg = "invalid command (type \"help\" for commands and arguments)\n\n";
static const char *inv_arg_msg = "invalid value (type \"help\" for commands and arguments)\n\n";

uint16_t spi_readwrite(uint16_t data);
void term_write(int angle);
void term_read(int &new_angle, int &new_period, int current_angle);
int parse_cmd_int_arg(const std::string &cmd_buf);

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

    int angle = 0, new_angle = 0;
    int period = 0, new_period = 20;

    // assign interrupts
    button_a.rise([&new_angle](){
        ++new_angle;
        if (new_angle > 360)
            new_angle = 0;
    });
    button_b.rise([&new_angle](){
        --new_angle;
        if (new_angle < 0)
            new_angle = 360;
    });

    serial_port.write(help_msg, strlen(help_msg));
    while(true)                 
    {    
        term_read(new_angle, new_period, 360);
        if (angle != new_angle) {
            angle = new_angle;
            tx = ANGLE << 12;
            tx += (uint16_t)angle;
            rx = spi_readwrite(tx);
        }
        if (period != new_period) {
            period = new_period;
            tx = PWM_PERIOD << 12;
            tx += (uint16_t)period;
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

void term_read(int &new_angle, int &new_period, int current_angle)
{
    typedef enum {
        READ_CMD,
        PARSE_CMD
    } term_state_t;
    static term_state_t state = READ_CMD;
    
    char c = 0;
    static std::string buf;

    switch (state) {
        case READ_CMD: {
            if (serial_port.read(&c, 1) != -EAGAIN) {
                serial_port.write(&c, 1);
                if (c == '\r') {
                    c = '\n';
                    serial_port.write(&c, 1);
                    state = PARSE_CMD;
                } else if (c) {
                    buf += c;
                }
            }
            break;
        }
        case PARSE_CMD: {
            if (buf.find("help") == 0) {
                serial_port.write(help_msg, strlen(help_msg));
            } 
            else if (buf.find("angle") == 0) {
                int val = parse_cmd_int_arg(buf);
                if (val < 0 || val > 360)
                    serial_port.write(inv_arg_msg, strlen(inv_arg_msg));
                else
                    new_angle = val;
            }
            else if (buf.find("period") == 0) {
                int val = parse_cmd_int_arg(buf);
                if (val < 0 || val > 255)
                    serial_port.write(inv_arg_msg, strlen(inv_arg_msg));
                else
                    new_period = val;
            }
            else if (buf.find("ctrl") == 0) {
                if (buf.find("bang") == 5)
                    ;// sent bang-bang control
                else if (buf.find("prop") == 5)
                    ;// sent proportional control
                else 
                    serial_port.write(inv_arg_msg, strlen(inv_arg_msg));
            }
            else if (buf.find("cmd") == 0) {
                if (buf.find("cont") == 4)
                    ;
                else if (buf.find("zero") == 4)
                    ;
                else if (buf.find("brake") == 4)
                    ;
                else 
                    serial_port.write(inv_arg_msg, strlen(inv_arg_msg));
            }
            else if (buf.find("power") == 0) {
                if (buf.find("on") == 6)
                    ;
                else if (buf.find("off") == 6)
                    ;
                else 
                    serial_port.write(inv_arg_msg, strlen(inv_arg_msg));
            }
            else if (buf.find("status") == 0) {
                std::string status = "current angle: " + std::to_string(current_angle) + "\n";
                serial_port.write(status.c_str(), status.length());
            }
            else {
                serial_port.write(inv_cmd_msg, strlen(inv_cmd_msg));
            }

            buf.erase();
            state = READ_CMD;
            break;
        }
    }
}

int parse_cmd_int_arg(const std::string &cmd_buf)
{
    auto pos = cmd_buf.find_first_of(" ");
    if (pos == std::string::npos || cmd_buf[pos + 1] == '\0')
        return -1;
    if (cmd_buf[pos + 1] < '0' || cmd_buf[pos + 1] > '9')
        return -1;
    return stoi(cmd_buf.substr(pos + 1));
}
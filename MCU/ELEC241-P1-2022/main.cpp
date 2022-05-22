#include "uop_msb.h"
#include <cstdint>
#include <string>

DigitalIn DO_NOT_USE(PB_12); // This Pin is connected to the 5VDC from the FPGA card and an INPUT that is 5V Tolerant

// serial peripheral interface (SPI)
SPI spi(PA_7, PA_6, PA_5); // mosi, miso, sclk
DigitalOut cs(PC_6);       // chip select

// module support board buttons a & b
static InterruptIn button_a(PG_0), button_b(PG_1);

typedef enum : uint16_t {
    INSTR_ILLEGAL = 0,
    INSTR_READBACK,
    INSTR_ANGLE, 
    INSTR_PWM_PERIOD, 
    INSTR_CTRL_MODE, 
    INSTR_COMMAND, 
    INSTR_PWM_POWER,
} InstrType;

enum CtrlMode : uint16_t {
    BANG_BANG = 0,
    PROPORTIONAL,
};

enum Command : uint16_t {
    CONTINUOUS_MODE = 0,
    RESET_ZERO_ANGLE,
    BRAKE,
};

// buffered serial for terminal connection
static BufferedSerial serial_port(USBTX, USBRX);
static const std::string help_msg = R"(
commands:
    help   (show this menu)
    status (display current servo angle)
    angle  [0..360]
    period [0..255] (255 = 0.0255s)
    ctrl   [bang|prop]
    cmd    [cont|zero|brake]
    power  [on|off]

)";
static const std::string inv_cmd_msg = "invalid command (type \"help\" for commands and arguments)\n\n";
static const std::string inv_arg_msg = "invalid value (type \"help\" for commands and arguments)\n\n";

uint16_t spi_readwrite(uint16_t data);
uint16_t convert_angle_to_pulses(int angle);
int convert_pulses_readback_to_angle(uint16_t pulses);
uint16_t create_instr(InstrType type, uint16_t data);
uint16_t term_read(int current_angle);
int parse_cmd_int_arg(const std::string &cmd_buf);

int main() {
    //SET UP THE SPI INTERFACE
    cs = 1;                     // Chip must be deselected, Chip Select is active LOW
    spi.format(16,0);           // Setup the DATA frame SPI for 16 bit wide word, Clock Polarity 0 and Clock Phase 0 (0)
    spi.frequency(1000000);     // 1MHz clock rate
    wait_us(10000);

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
    uint16_t instr, new_instr, pulses_readback = 0;

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

    serial_port.write(help_msg.c_str(), help_msg.length());
    while(true)                 
    {    
        new_instr = term_read(convert_pulses_readback_to_angle(pulses_readback));
        if (angle != new_angle) { // check if angle has been updated
            angle = new_angle;
            pulses_readback = spi_readwrite(create_instr(INSTR_ANGLE, convert_angle_to_pulses(angle)));
        }
        if (new_instr && (instr != new_instr)) { // check for new valid instruction
            instr = new_instr;
            pulses_readback = spi_readwrite(instr);
        }
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

uint16_t convert_angle_to_pulses(int angle)
{
    return angle * (1006 / 360);
}

int convert_pulses_readback_to_angle(uint16_t pulses)
{
    return (~(INSTR_READBACK << 12) & pulses) * 360 / 1006;
}

uint16_t create_instr(InstrType type, uint16_t data)
{
    return (type << 12) | (data & 0x0FFF);
}

uint16_t term_read(int current_angle)
{
    typedef enum {
        READ_CMD,
        PARSE_CMD
    } TermState;
    static TermState state = READ_CMD;
    
    char c = 0;
    static std::string buf;

    InstrType instr_type = INSTR_ILLEGAL;
    uint16_t instr_data = 0;

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
        case PARSE_CMD: { // i think the use of goto is justified... idk
            if (buf.find("help") == 0) {
                serial_port.write(help_msg.c_str(), help_msg.length());
            } 
            else if (buf.find("angle") == 0) {
                instr_type = INSTR_ANGLE;
                int angle = parse_cmd_int_arg(buf);
                if (angle < 0 || angle > 360)
                    goto INVALID_ARG;
                else
                    instr_data = convert_angle_to_pulses(angle);
            }
            else if (buf.find("period") == 0) {
                instr_type = INSTR_PWM_PERIOD;
                int period = parse_cmd_int_arg(buf);
                if (period < 0 || period > 255)
                    goto INVALID_ARG;
                else
                    instr_data = period;
            }
            else if (buf.find("ctrl") == 0) {
                instr_type = INSTR_CTRL_MODE;
                if (buf.find("bang") == 5)
                    instr_data = BANG_BANG;
                else if (buf.find("prop") == 5)
                    instr_data = PROPORTIONAL;
                else 
                    goto INVALID_ARG;
            }
            else if (buf.find("cmd") == 0) {
                instr_type = INSTR_COMMAND;
                if (buf.find("cont") == 4)
                    instr_data = CONTINUOUS_MODE;
                else if (buf.find("zero") == 4)
                    instr_data = RESET_ZERO_ANGLE;
                else if (buf.find("brake") == 4)
                    instr_data = BRAKE;
                else 
                    goto INVALID_ARG;
            }
            else if (buf.find("power") == 0) {
                instr_type = INSTR_PWM_POWER;
                if (buf.find("on") == 6)
                    instr_data = 0;
                else if (buf.find("off") == 6)
                    instr_data = 1;
                else 
                    goto INVALID_ARG;
            }
            else if (buf.find("status") == 0) {
                std::string status = "current angle: " + std::to_string(current_angle) + "\n\n";
                serial_port.write(status.c_str(), status.length());
            }
            else {
                serial_port.write(inv_cmd_msg.c_str(), inv_cmd_msg.length());
            }

            buf.erase();
            state = READ_CMD;
            break;

            INVALID_ARG:
            instr_type = INSTR_ILLEGAL;
            serial_port.write(inv_arg_msg.c_str(), inv_arg_msg.length());
            buf.erase();
            state = READ_CMD;
        }
    }

    return create_instr(instr_type, instr_data);
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
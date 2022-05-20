#include "mbed.h"
#ifndef __ELEC241__
#define __ELEC241__

typedef enum {
    READBACK = 0,
    ANGLE, 
    PWM_PERIOD, 
    CTRL_MODE, 
    COMMAND, 
    PWM_POWER, 
    ILLEGAL
} Instr;

uint16_t fpga_word(Instr u, uint16_t payload);

#endif

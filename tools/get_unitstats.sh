#!/bin/bash
./gnatprove_unitstats.py -t -p --sort=coverage,success ../obj/gnatprove ../software/hal/lib/obj/gnatprove ../software/hal/boards/obj/pixhawk/gnatprove ../software/hal/hpl/STM32/obj/stm32f42x/gnatprove

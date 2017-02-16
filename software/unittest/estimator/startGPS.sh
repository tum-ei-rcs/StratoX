#!/usr/bin/env bash

PATH=$HOME/Software/gnatpro/bin:$PATH
export PATH

gps -P./default.gpr

# exit with error code
exit 0

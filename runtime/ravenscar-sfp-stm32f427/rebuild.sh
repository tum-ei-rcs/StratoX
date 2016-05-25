#!/bin/bash
# Rebuild RTS from command line
# <becker@rcs.ei.tum.de>
# 2016-05-25

echo "this is untested. open file and uncomment line manually".
gprbuild --target=arm-eabi -d -P ravenscar_build.gpr

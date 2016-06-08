#!/bin/bash
# Rebuild RTS from command line
# <becker@rcs.ei.tum.de>
# 2016-05-25

echo "Rebuilding Ravenscar SFP RTS..."

if [ ! -d "adalib" ]; then mkdir adalib; fi
if [ ! -d "obj" ]; then mkdir obj; fi
gprbuild --target=arm-eabi -d -P ravenscar_build.gpr

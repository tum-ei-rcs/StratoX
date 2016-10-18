#!/usr/bin/env bash

PATH=$HOME/Software/gnatpro/bin:$PATH
export PATH

gprbuild -Psitest.gpr

# exit with error code
exit 0

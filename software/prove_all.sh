#!/bin/bash
TIME=/usr/bin/time -v

$TIME gnatprove -XBUILD_MODE=Analyze -P stratox.gpr -j4 -k --level=2 --mode=prove --report provers --prover=altergo,cvc4

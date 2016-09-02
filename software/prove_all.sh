#!/bin/bash
TIME=/usr/bin/time -v

$TIME gnatprove -XBUILD_MODE=Analyze -P stratox.gpr -j8 -k --level=2 --mode=prove --report provers --prover=altergo,cvc4,z3 --timeout=60

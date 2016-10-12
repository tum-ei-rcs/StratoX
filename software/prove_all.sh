#!/bin/bash
#
OBJ=../obj/gnatprove


TIME="/usr/bin/time -v"
OUTDIR=../obj/gnatprove # where gnatprove generates its logs and reports
PROVEOPTS="--pedantic -v" # warns if arithmetic operations could be reorderd, which may refute a proof
if [ "`hostname`" == "rr-u1204-1" ]; then
	# server
	CORES=0 # auto
	TIMEOU=10000 # make it high, because cvc4 seems to deadlock when timeout triggers
	PROVERS=cvc4,z3,altergo
	PROOF=per_check:all
	STEPS=100
else
	# laptop etc.
	CORES=2
	TIMEOU=auto
	PROVERS=cvc4,altergo,z3
	PROOF=per_check
	STEPS=10
	# if you use --level=n, then this overwrites and sets a combination of prover, proof and steps
fi

# clean old logs
rm -f $OBJ/gnatprove_flow.out
rm -f $OBJ/gnatprove_prove.out
rm -f $OBJ/filestats.log

# do it
#gprbuild -p -P stratox.gpr

# flow mode
$TIME gnatprove -XBuild_Mode=Analyze -P stratox.gpr ${PROVEOPTS} -j${CORES} -k --mode=flow --report all --prover${PROVERS} || true
cp $OBJ/gnatprove.out $OBJ/gnatprove_flow.out || true

# prove mode
$TIME gnatprove -XBuild_Mode=Analyze -P stratox.gpr ${PROVEOPTS} -j${CORES} -k --mode=prove --report provers --prover=${PROVERS} --timeout=${TIMEOU} --proof=${PROOF} --steps=${STEPS} | tee $OBJ/analysis.log || true
cp $OBJ/gnatprove.out $OBJ/gnatprove_prove.out || true

# make statistics
../tools/gnatprove_filestats.py --sort=coverage,success,props --table $OBJ/gnatprove_prove.out $OBJ/analysis.log | tee $OBJ/filestats.log

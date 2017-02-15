#!/bin/bash
# 
# this is for jenkins to run gnatprove.

# where are the gnatprove outputs and the project file?
REPO=..
PRJ=stratox.gpr
OBJ=${REPO}/obj/gnatprove
GPFLAGS=-XBuild_Mode=Analyze
OBJ_OTHER="${REPO}/software/hal/boards/obj/pixhawk/gnatprove \
${REPO}/software/hal/hpl/STM32/obj/stm32f42x/gnatprove \
${REPO}/software/hal/hal/STM32/obj/gnatprove \
${REPO}/software/hal/hal/obj/gnatprove"
OBJ_ALL="$OBJ $OBJ_OTHER"

##### SCRIPT STARTS HERE

##############
# PROOF PARAMS
###############
TIME="/usr/bin/time -v"
PROVEOPTS="--pedantic -v" # warns if arithmetic operations could be reorderd, which may refute a proof
if [ "`hostname`" == "rr-u1204-1" ]; then
	# server
	CORES=0 # auto
	TIMEOU=100 # make it high, because cvc4 seems to deadlock when timeout trigger. seems to be seconds per VC.
	PROVERS=cvc4,z3,altergo #,mathsat,gappa
	PROOF=per_check:all
	STEPS=10000
else
	# laptop etc.
	CORES=2
	TIMEOU=10
	PROVERS=cvc4,altergo,z3
	PROOF=per_check:all
	STEPS=1000
	# if you use --level=n, then this overwrites and sets a combination of prover, proof and steps
fi

###########
# DEBUG
###########

# clean old logs
rm -f $OBJ/gnatprove_flow.out
rm -f $OBJ/gnatprove_prove.out
rm -f $OBJ/filestats.log
rm -f $OBJ/unitstats.log
rm -f $OBJ/analysis.log

########
# do it
########

# clean (optional; it is necessary when above parameters have changed, but increases analysis time!)
gnatprove -P $PRJ --clean
 
##################
# analyze project
##################
mkdir -p $OBJ # because otherwise 'gprbuild --clean' has the target for our log deleted

# flow mode
#$TIME gnatprove $GPFLAGS -P $PRJ ${PROVEOPTS} -j${CORES} -k --mode=flow --report=all --prover=${PROVERS} || true
#cp $OBJ/gnatprove.out $OBJ/gnatprove_flow.out || true

# prove mode
$TIME gnatprove $GPFLAGS -P $PRJ ${PROVEOPTS} -j${CORES} -k --mode=prove --report=statistics --prover=${PROVERS} --timeout=${TIMEOU} --proof=${PROOF} --steps=${STEPS} | tee $OBJ/analysis.log || true
cp $OBJ/gnatprove.out $OBJ/gnatprove_prove.out || true
    
##################
# make statistics
##################
${REPO}/tools/gnatprove_unitstats.py --sort=coverage,success,props --table $OBJ_ALL | tee $OBJ/unitstats.log || true

exit 0

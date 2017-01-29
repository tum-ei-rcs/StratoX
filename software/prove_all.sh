#!/bin/bash
# 
# runs gnatprove while saving the logs, and then runs a Python script over it to extract statistics.
# arguments:
#  1. (optional) prefix for logs
#  2. (optional) target directory for logs. If empty=obj

OBJ=../obj/gnatprove
PRJ=stratox.gpr

echo $0

if [ ! -z "$1" ]; then
    PREFIX="${1}_"
    echo "Prefix=$PREFIX"
else
    PREFIX=""
fi
if [ ! -z "$2" ]; then
    TAR=$2
    echo "TAR=$TAR"
else
    TAR=$OBJ
fi

TIME="/usr/bin/time -v"
PROVEOPTS="--pedantic -v" # warns if arithmetic operations could be reorderd, which may refute a proof
if [ "`hostname`" == "rr-u1204-1" ]; then
	# server
	CORES=0 # auto
	TIMEOU=100 # make it high, because cvc4 seems to deadlock when timeout trigger. seems to be seconds per VC.
	PROVERS=cvc4,z3,altergo,mathsat,gappa
	PROOF=per_check:all
	STEPS=1000
else
	# laptop etc.
	CORES=2
	TIMEOU=auto
	PROVERS=cvc4,altergo,z3
	PROOF=per_check
	STEPS=10
	# if you use --level=n, then this overwrites and sets a combination of prover, proof and steps
fi

###########
# DEBUG
###########
echo "Proving all of $PRJ into $TAR with prefix $PREFIX"

# clean old logs
rm -f $TAR/${PREFIX}gnatprove_flow.out
rm -f $TAR/${PREFIX}gnatprove_prove.out
rm -f $TAR/${PREFIX}filestats.log

# do it
#gprbuild -p -P $PRJ

# clean (necessary when above parameters have changed, but increases analysis time!)
gnatprove -P $PRJ --clean

# flow mode
$TIME gnatprove -XBuild_Mode=Analyze -P $PRJ ${PROVEOPTS} -j${CORES} -k --mode=flow --report=all --prover=${PROVERS} || true
cp $OBJ/gnatprove.out $TAR/${PREFIX}gnatprove_flow.out || true

# prove mode
$TIME gnatprove -XBuild_Mode=Analyze -P $PRJ ${PROVEOPTS} -j${CORES} -k --mode=prove --report=provers --prover=${PROVERS} --timeout=${TIMEOU} --proof=${PROOF} --steps=${STEPS} | tee $TAR/${PREFIX}analysis.log || true
cp $OBJ/gnatprove.out $TAR/${PREFIX}gnatprove_prove.out || true

# make statistics
../tools/gnatprove_filestats.py --sort=coverage,success,props --table $TAR/${PREFIX}gnatprove_prove.out $TAR/${PREFIX}analysis.log | tee $TAR/${PREFIX}filestats.log

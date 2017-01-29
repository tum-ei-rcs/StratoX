#!/bin/bash
# 
# runs gnatprove while saving the logs, and then runs a Python script over it to extract statistics.
# arguments:
#  1. (optional) prefix for logs
#  2. (optional) target directory for logs. If empty=obj

# where are the gnatprove outputs and the project file?
OBJ=../obj/gnatprove
PRJ=stratox.gpr
GPFLAGS=-XBuild_Mode=Analyze

# set the following to something non-empty, to analyze all sources individually instead of entire project
INDIVIDUAL=


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

###############
# FUNCTIONS
###############
get_project_units () {
    rm -f $TAR/_files* $TAR/_units*
    # compile and get file list through this
    gprbuild -P${PRJ} -gnatd.n > $TAR/_files.0
    # filter out lines which are no file paths, and collapse file names to package names
    for f in `cat $TAR/_files.0`; do
        if [ -f $f ]; then
            echo $f >> $TAR/_files.1
        fi;
    done
    # filter out some specific files (e.g., runtime)
    grep -v ravenscar $TAR/_files.1 | grep -v 'hal/hpl' > $TAR/_files.2
    # collapse file names to unit names
    for f in `cat $TAR/_files.2`; do
        unit=$(basename $f)
        echo ${unit%.*} >> $TAR/_units.0
    done
    # remove duplicates
    cat $TAR/_units.0 | sort | uniq > $TAR/_units
    UNITS=$(cat $TAR/_units)
}

###############
# PROOF PARAMS
###############
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
rm -f $TAR/${PREFIX}analysis.log

########
# do it
########

# clean (optional; it is necessary when above parameters have changed, but increases analysis time!)
gnatprove -P $PRJ --clean

mkdir -p $TAR

if [ ! -z "$INDIVIDUAL" ]; then
    ##################
    # iterate files
    ##################
    gnatprove -P $PRJ --clean # we definitely need it here
    get_project_units
    for u in $UNITS; do        
        # prove
        $TIME gnatprove $GPFLAGS -P $PRJ ${PROVEOPTS} -j${CORES} -k --mode=prove --report=provers --prover=${PROVERS} --timeout=${TIMEOU} --proof=${PROOF} --steps=${STEPS} -u $u | tee -a $TAR/${PREFIX}analysis.log || true
        #echo "Unit=${u}:" >> $TAR/${PREFIX}gnatprove_prove.out
        #cat $OBJ/gnatprove.out >> $TAR/${PREFIX}gnatprove_prove.out || true
    done
    # reports accumulate in gnatprove.out, so we only need to copy once
    cp $OBJ/gnatprove.out $TAR/${PREFIX}gnatprove_prove.out || true
else
    ##################
    # analyze project
    ##################
    
    # flow mode
    #$TIME gnatprove $GPFLAGS -P $PRJ ${PROVEOPTS} -j${CORES} -k --mode=flow --report=all --prover=${PROVERS} || true
    #cp $OBJ/gnatprove.out $TAR/${PREFIX}gnatprove_flow.out || true

    # prove mode
    $TIME gnatprove $GPFLAGS -P $PRJ ${PROVEOPTS} -j${CORES} -k --mode=prove --report=provers --prover=${PROVERS} --timeout=${TIMEOU} --proof=${PROOF} --steps=${STEPS} | tee $TAR/${PREFIX}analysis.log || true
    cp $OBJ/gnatprove.out $TAR/${PREFIX}gnatprove_prove.out || true
fi

##################
# make statistics
##################
../tools/gnatprove_filestats.py --sort=coverage,success,props --table $TAR/${PREFIX}gnatprove_prove.out $TAR/${PREFIX}analysis.log | tee $TAR/${PREFIX}filestats.log

exit 0

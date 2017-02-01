#!/bin/bash
# 
# runs gnatprove while saving the logs, and then runs a Python script over it to extract statistics.
# arguments:
#  1. (optional) prefix for logs
#  2. (optional) target directory for logs. If empty=obj

# where are the gnatprove outputs and the project file?
REPO=$HOME/async/StratoX.git/
OBJ=${REPO}/obj/gnatprove
PRJ=${REPO}/software/stratox.gpr
GPFLAGS=-XBuild_Mode=Analyze
OBJ_OTHER="${REPO}/software/hal/boards/obj/pixhawk/gnatprove \
${REPO}/software/hal/hpl/STM32/obj/stm32f42x/gnatprove \
${REPO}/software/hal/hal/STM32/obj/gnatprove \
${REPO}/software/hal/hal/obj/gnatprove"
OBJ_ALL="$OBJ $OBJ_OTHER"
COPY_FOLDERS=$OBJ_ALL

# set the following to something non-empty, to analyze all sources individually instead of entire project
INDIVIDUAL=

##### SCRIPT STARTS HERE

if [ ! -z "$1" ]; then
    PREFIX="${1}"
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
    # collapse file names to unit names
    for f in `cat $TAR/_files.1`; do
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
	TIMEOU=10
	PROVERS=cvc4,altergo,z3
	PROOF=per_check
	STEPS=100
	# if you use --level=n, then this overwrites and sets a combination of prover, proof and steps
fi

###########
# DEBUG
###########
echo "Proving all of $PRJ into $TAR with prefix $PREFIX"

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
#gnatprove -P $PRJ --clean

if [ ! -z "$INDIVIDUAL" ]; then
    ##################
    # iterate files
    ##################
    gnatprove -P $PRJ --clean # we definitely need it here
    mkdir -o $OBJ # because otherwise 'gprbuild --clean' has the target for our log deleted
    get_project_units
    for u in $UNITS; do        
        # prove
        $TIME gnatprove $GPFLAGS -P $PRJ ${PROVEOPTS} -j${CORES} -k --mode=prove --report=provers --prover=${PROVERS} --timeout=${TIMEOU} --proof=${PROOF} --steps=${STEPS} -u $u | tee -a $OBJ/analysis.log || true
        #echo "Unit=${u}:" >> $OBJ/gnatprove_prove.out
        #cat $OBJ/gnatprove.out >> $OBJ/gnatprove_prove.out || true
        # reports accumulate in gnatprove.out, so we only need to copy once in the end
    done

    cp $OBJ/gnatprove.out $OBJ/gnatprove_flow.out || true
    
else
    ##################
    # analyze project
    ##################
    mkdir -p $OBJ # because otherwise 'gprbuild --clean' has the target for our log deleted

    # flow mode
    #$TIME gnatprove $GPFLAGS -P $PRJ ${PROVEOPTS} -j${CORES} -k --mode=flow --report=all --prover=${PROVERS} || true
    #cp $OBJ/gnatprove.out $OBJ/gnatprove_flow.out || true

    # prove mode
    $TIME gnatprove $GPFLAGS -P $PRJ ${PROVEOPTS} -j${CORES} -k --mode=prove --report=provers --prover=${PROVERS} --timeout=${TIMEOU} --proof=${PROOF} --steps=${STEPS} | tee $OBJ/analysis.log || true
    cp $OBJ/gnatprove.out $OBJ/gnatprove_prove.out || true
    
fi

##################
# make statistics
##################
${REPO}/tools/gnatprove_unitstats.py --sort=coverage,success,props --table $OBJ_ALL | tee $OBJ/unitstats.log || true
${REPO}/tools/gnatprove_filestats.py --sort=coverage,success,props --table $OBJ/gnatprove_prove.out $OBJ/analysis.log | tee $OBJ/filestats.log || true

############
# copy data
############
if [ ! "$TAR" == "$OBJ" ]; then
    # copy all folders to target
    mkdir -p $TAR/$PREFIX
    cnt=0
    echo "copy_folders=$COPY_FOLDERS"
    for o in $COPY_FOLDERS; do
        echo "Copying $o to $TAR/$PREFIX..."
        cnt=$((cnt+1))
        cp -R $o $TAR/${PREFIX}/gnatprove_${cnt} || true        
    done    
    # save space: remove some files
    find $TAR/${PREFIX} -type f -name \*.ali -exec rm -f {} \;
    find $TAR/${PREFIX} -type f -name \*.mlw -exec rm -f {} \;
fi

exit 0

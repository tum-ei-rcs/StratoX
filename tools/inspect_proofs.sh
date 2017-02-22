#!/bin/bash
#
# This script starts the why3 IDE on a given mlw file, to allow deep inspection
# of the proofs and possibly manual fiddling.

# note that why3 must be re-build manually from the AdaCore git repo to enable
# the GUI.

# default path (try to auto-detect below)
SPARKPATH=/opt/spark2016/bin

PATHS=$(echo $PATH | tr ":" "\n")
for i in $PATHS; do
    if [[ $i =~ .*spark.* ]] || [[ $i =~ .*SPARK.* ]] ; then
	echo "Auto-detected SPARK installation at $i"
        SPARKPATH=$i
        break;
    fi;
done

if [ "$#" -lt 1 ]; then
    echo "Must at least provide one argument (.mlw file)"
    exit 2;
fi

#/home/becker/bin/why3-adacore/bin/why3 prove -P alt-ergo-prv -L $SPARKPATH/../share/spark/theories $1
#$SPARKPATH/../libexec/spark/bin/why3 prove -P alt-ergo-prv -L $SPARKPATH/../share/spark/theories $1
$SPARKPATH/../libexec/spark/bin/why3 ide --debug-all -L $SPARKPATH/../share/spark/theories $1
#why3 ide -L $SPARKPATH/../share/spark/theories $1

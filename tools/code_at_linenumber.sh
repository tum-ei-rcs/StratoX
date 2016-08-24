#!/bin/bash
#
# prints code from all files at the given line

LINE=$1
if [ -z "$LINE" ]; then
    echo "please give line number as argument"
    exit 1;
fi;

for f in `find . -name \*.ad?`; do
    CNT=`sed -n ${1}p $f`;
    CODE=`echo $CNT | sed 's/--.*\$//g'` # strip ada comments
    if [ ! -z "$CODE" ]; then
        echo "$f: $CODE";
    fi
done

#!/bin/bash

PACKAGENAME=STM32_SVD # requires to use svd2ada with argument "-p STM32_SVD"
if [ -z "$1" ]; then
	echo "one argument required, which is a folder name!"
	exit 1
fi;
echo "remapping stm32_svd datatypes to HAL in $1 ..."

# replace all those things below by HAL
# stm32_svd.UInt22 -> HAL.UInt22

FILES=`find $1 -name \*.ads`
for f in $FILES; do
    cp $f ${f}.tmp
    sed -i 's/'$PACKAGENAME'.UInt\([0-9][0-9]*\)/HAL.UInt\1/g' ${f}.tmp
    sed -i 's/'$PACKAGENAME'.Int\([0-9][0-9]*\)/HAL.Int\1/g' ${f}.tmp
    TYPES="Word Bit Short Byte"
    for t in $TYPES; do 
        sed -i 's/'$PACKAGENAME'.'$t'/HAL.'$t'/g' ${f}.tmp
    done
    sed -i 's/with System;/with System;\nwith HAL;/g' ${f}.tmp
    mv ${f}.tmp $f
done

echo "Done."

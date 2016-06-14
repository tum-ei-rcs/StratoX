#!/bin/sh
# this is used for bugreports to AdaCore. If a bug is triggered by
# some file A, then use this to determine closure for given file 
# and make an archive from it to be sent to AdaCore

if [ -z "$1" ]; then
	echo "need one argument (file name w/o path)"
	exit 1
fi

# collect closure
gprbuild -c -f px4io-driver.adb -Pstratox.gpr -gnatd.n|grep -v adainclude|grep -v ^arm-eabi-gcc|sort|uniq > closure.tmp

# manually add some more files
find . -name \*.gpr >> closure.tmp
find . -name \*.adc >> closure.tmp
find . -name target.atp >> closure.tmp

# archive
tar -cvzf ${1}.closure.tgz -T closure.tmp

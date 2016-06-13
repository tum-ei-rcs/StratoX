#!/bin/bash

# those have already been treated, skip auto-sparkification
BLACKLIST="a-taside.ads a-exetim.ads a-reatim.ads a-sytaco.ads"

# auto-sparkification not for those, as they have forbidden features:
BLACKLIST="$BLACKLIST a-except.ads s-bbmcpa.ads i-stm32.ads i-stm32-rcc.ads i-stm32-gpio.ads i-stm32-syscfg.ads s-bbthre.ads s-bbthqu.ads s-mufalo.ads s-musplo.ads a-tags.ads s-osinte.ads s-bbcppr.ads s-bbtime.ads s-bbinte.ads"

for f in `find . -name \*.ads`; do 
    bn=`basename $f`
    if [[ $BLACKLIST =~ $bn ]]; then
        echo "### Skipping file $f"
    else
        # skip Pure packages
        if ! grep --quiet -i "pragma pure" $f; then
	    sed -i 's/^package \(.*\) is/package \1\nwith SPARK_Mode => On is/g' $f;
	    sed -i 's/^private$/private\npragma SPARK_Mode (Off);/g' $f
        fi
    fi
done

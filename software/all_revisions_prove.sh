#!/bin/bash
#
# Usage: script.sh 7dc288b30c976d02383ae8dda6b760a21800a751..HEAD
# Copy this script to /tmp, then adjust paths below.
#

if [ $# -lt 1 ]; then
  echo "Need one argument denoting revision range, e.g.: '7dc288b30c976d02383ae8dda6b760a21800a751..HEAD'"
  exit 1;
fi

##########
# PATHS
##########
PROVESCRIPT=/tmp/prove_all.sh # script to be called on each revision
LOGDIR=/tmp/allrevs
REPO=~/async/StratoX.git
(
    cd $REPO
    mkdir -p $LOGDIR
    REVS=$(git rev-list --date-order "$1")    
    echo "revs=$REVS"
    while read -r rev; do
        CDATE=$(git log -1 $rev --format="%cd" --date=iso | sed 's/ /_/g')
        CSUBJ=$(git log -1 $rev --format="%s")
        echo "Date=$CDATE, comment=$CSUBJ"
        git checkout "$rev"
        echo " "
        $PROVESCRIPT $CDATE $LOGDIR
    
    done < <(git rev-list --date-order "$1")
    git checkout master
)
exit 0

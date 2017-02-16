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
BRANCH=master
PROVESCRIPT=~/stratox.hist/prove_all.sh # script to be called on each revision
LOGDIR=~/stratox.hist
REPO=~/async/StratoX.git
LOG=revisions.txt
(
    cd $REPO
    git checkout $BRANCH
    mkdir -p $LOGDIR
    rm -f $LOGDIR/$LOG
    while read -r rev; do
        CDATE=$(git log -1 $rev --format="%cd" --date=iso | sed 's/ /_/g')
        CSUBJ=$(git log -1 $rev --format="%s")
        CBRNCH=$(git name-rev --name-only HEAD)
	NOWD=$(date +"%Y-%m-%d_%T")
        echo "$NOWD: commit_date=$CDATE, branch=$CBRNCH, rev=$rev, comment=$CSUBJ" | tee -a $LOGDIR/$LOG
        git checkout "$rev"
        echo " "
        $PROVESCRIPT $CDATE $LOGDIR
    
    done < <(git rev-list --reverse --branches=$BRANCH --date-order "$1")
    git checkout $BRANCH
)
exit 0

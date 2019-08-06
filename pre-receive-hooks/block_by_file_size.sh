#!/usr/bin/env bash

#
# Pre-receive hook that will block any new commits that contain a file, or the whole commit, that is larger than size in bytes
MAX_SIZE=100000

#
# More details on pre-receive hooks and how to apply them can be found on
# https://help.github.com/enterprise/admin/guides/developer-workflow/managing-pre-receive-hooks-on-the-github-enterprise-appliance/
#

while read oldrev newrev refname; do
  # Looking at total commit size
  TOTAL=0
  
  for SIZE in `git rev-list $oldrev..$newrev --objects --all \
              | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' \
              | sed -n 's/^blob //p' \
              | sort --numeric-sort --key=2 \
              | cut -d " " -f 2`
  do 
     if [ ${SIZE} -gt ${MAX_SIZE} ]
     then
        echo "Error: File sized at ${SIZE} bytes is in a commit. The maximum allowed is ${MAX_SIZE} bytes."
        exit 1
     fi
     
     # Now check total commit size and exit immediatly if it fails.
     TOTAL=$(($TOTAL + $SIZE))
     if [ ${TOTAL} -gt ${MAX_SIZE} ]
     then
        echo "Error: The commit ${newrev} is ${TOTAL} bytes or more. The maximum allowed is ${MAX_SIZE} bytes."
        exit 2
     fi
  done
done

exit 0

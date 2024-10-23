#!/usr/bin/env bash
#
# Check and reject commits with "skip-checks: true" trailer lines.
# 
# This hook basically disables the following feature:
# https://help.github.com/articles/about-status-checks/#skipping-and-requesting-checks-for-individual-commits

ERROR_MSG="[POLICY] Skipping checks is not allowed. Please remove trailer lines with \"skip-checks: true\"."

while read OLDREV NEWREV REFNAME ; do
  for COMMIT in `git rev-list $OLDREV..$NEWREV`;
  do
    MESSAGE=`git cat-file commit $COMMIT | git interpret-trailers --parse`
    if echo $MESSAGE | grep -iq "skip-checks: true"; then
      echo "$ERROR_MSG" >&2
      exit 1
    fi
  done
done
exit 0
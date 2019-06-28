#!/bin/bash
#
# check commit messages for JIRA issue numbers formatted as JIRA-<issue number> for any project e.g. FT-1097
#
# Can check which commit messages (of the last however-many) would not be allowed:
# git log -n 10000 --pretty=format:%s | grep -vE "^(Merge|.*[A-Z]+\-[0-9]+)" | sort -u

ERROR_MSG="[POLICY] The commit doesn't reference a JIRA issue"

while read OLDREV NEWREV REFNAME ; do
  STARTING_COMMIT=$OLDREV
  if [ "$OLDREV" == "0000000000000000000000000000000000000000" ]; then
    STARTING_COMMIT="refs/heads/master"
  fi
  
  message=$(git log --pretty=format:"%s %b -~-" $STARTING_COMMIT..$NEWREV | \
      awk 'BEGIN{RS="-~-\n"; found=0 } !/^(Merge|.*[A-Z]+-[0-9]+)/ {print NR, $0; found=1;} END{exit found}')

  if [ $? -ne 0 ]
  then
      echo "$ERROR_MSG: $message" >&2
      exit 1
  fi
done  

exit 0

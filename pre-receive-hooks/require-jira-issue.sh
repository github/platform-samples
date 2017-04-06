#!/usr/bin/env bash

zero_commit="0000000000000000000000000000000000000000"

read oldrev newrev refname
echo $oldrev $newrev $refname

check_message_format ()
# enforced custom commit message format
{
  message=`git cat-file commit $newrev | sed '1,/^$/d'`
  regex="/*\[jira-.*\]"
  echo "[COMMIT MESSAGE]:" $message
    if [[  $message =~ $regex ]];
  then
    echo "Commit message looks good!"
    exit 0
  else
    echo "[POLICY] Commit message does not contain a JIRA ticket #"
    exit 1

  fi
}

if [ "$newrev" = "$zero_commit" ]; then
  continue
else
  check_message_format
fi

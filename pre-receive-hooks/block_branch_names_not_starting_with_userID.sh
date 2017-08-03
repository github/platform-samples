#!/usr/bin/env bash

#
# Pre-receive hook that will block any new commits that their names do not being with the userID
#
# More details on pre-receive hooks and how to apply them can be found on
# https://help.github.com/enterprise/admin/guides/developer-workflow/managing-pre-receive-hooks-on-the-github-enterprise-appliance/
#

zero_commit="0000000000000000000000000000000000000000"

while read oldrev newrev refname; do
  # Only check new branches ($oldrev is zero commit), don't block tags
  if [[ $oldrev == $zero_commit && $refname =~ ^refs/heads/ ]]; then
    # Check if the branch name begins with the userID - NOTE THIS IS CASE SENSITIVE AT THE MOMENT
    if [[ ! $refname =~ ^refs/heads/$GITHUB_USER_LOGIN ]]; then
      echo "Hi, $GITHUB_USER_LOGIN Blocking creation of new branch $refname"
      echo "because it does not start with your username ($GITHUB_USER_LOGIN)"
      echo "as outlined in the branch naming policy guide"
      exit 1
    fi
  fi
done
# The following echoes may be enabled if you like. They are a purely a cosmetic
# demo item to show that it does not have to be just error messages passed back.
# echo "Hi $GITHUB_USER_LOGIN, allowing creation of new branch $refname"
# echo "because it does start with your username ($GITHUB_USER_LOGIN)"
# echo "as outlined in the branch naming policy guide - thank you!"
exit 0

#!/usr/bin/env bash

#
# Pre-receive hook that will block any new commits that their names contain
# other than lower-case alphabet characters (a-z).
#
# More details on pre-receive hooks and how to apply them can be found on
# https://help.github.com/enterprise/admin/guides/developer-workflow/managing-pre-receive-hooks-on-the-github-enterprise-appliance/
#

zero_commit="0000000000000000000000000000000000000000"

while read oldrev newrev refname; do
  # Prevent creation of new branches that don't match `^refs/heads/[a-z]+$`
  if [[ $oldrev == $zero_commit && ! $refname =~ ^refs/heads/[a-z]+$ ]]; then
    echo "Blocking creation of new branch $refname because it must only contain lower-case alphabet characters."
    exit 1
  fi
done
exit 0

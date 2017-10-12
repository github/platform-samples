#!/usr/bin/env bash

#
# Pre-receive hook that will block any unsigned commits and tagswhen pushed to a GitHub Enterprise repository
# The script will not actually validate the GPG signature (would need access to PKI)
# but just checks whether all new commits and tags have been signed
#
# More details on pre-receive hooks and how to apply them can be found on
# https://help.github.com/enterprise/admin/guides/developer-workflow/managing-pre-receive-hooks-on-the-github-enterprise-appliance/
#
# More details on GPG commit and tag signing can be found on
# https://help.github.com/articles/signing-commits-using-gpg/
#

zero_commit="0000000000000000000000000000000000000000"

# we have to change the home directory of GPG
# as in the default environment, /root/.gnupg is not writeable
export GNUPGHOME=/tmp/

# Do not traverse over commits that are already in the repository
# (e.g. in a different branch)
# This prevents funny errors if pre-receive hooks got enabled after some
# commits got already in and then somebody tries to create a new branch
# If this is unwanted behavior, just set the variable to empty
excludeExisting="--not --all"

while read oldrev newrev refname; do
  # echo "payload"
  echo $refname $oldrev $newrev

  # branch or tag get deleted
  if [ "$newrev" = "$zero_commit" ]; then
    continue
  fi

  # Check for new branch or tag
  if [ "$oldrev" = "$zero_commit" ]; then
    span=`git rev-list $newrev $excludeExisting`
  else
    span=`git rev-list $oldrev..$newrev $excludeExisting`
  fi

  for COMMIT in $span;
  do
    signed=$(git verify-commit $COMMIT 2>&1 | grep "gpg: Signature made")
    if test -n "$signed"; then
      echo Commit $COMMIT was signed by a GPG key: $signed
    else
      echo Commit $COMMIT was not signed by a GPG key, rejecting push
      exit 1
    fi
  done
done
exit 0

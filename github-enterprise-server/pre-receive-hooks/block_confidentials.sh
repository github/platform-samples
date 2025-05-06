#!/bin/bash

#
# ⚠ USE WITH CAUTION ⚠
#
# Pre-receive hook that will block any new commits that contain passwords,
# tokens, or other confidential information matched by regex
#
# More details on pre-receive hooks and how to apply them can be found on
# https://git.io/fNLf0
#

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
# Count of issues found in parsing
found=0

# Define list of REGEX to be searched and blocked
regex_list=(
  # block any private key file
  '(\-){5}BEGIN\s?(RSA|OPENSSH|DSA|EC|PGP)?\s?PRIVATE KEY\s?(BLOCK)?(\-){5}.*'
  # block AWS API Keys
  'AKIA[0-9A-Z]{16}'
  # block AWS Secret Access Key (TODO: adjust to not find validd Git SHA1s; false positives)
  # '([^A-Za-z0-9/+=])?([A-Za-z0-9/+=]{40})([^A-Za-z0-9/+=])?'
  # block confidential content
  'CONFIDENTIAL'
)

# Concatenate regex_list
separator="|"
regex="$( printf "${separator}%s" "${regex_list[@]}" )"
# remove leading separator
regex="${regex:${#separator}}"

# Commit sha with all zeros
zero_commit='0000000000000000000000000000000000000000'

# ------------------------------------------------------------------------------
# Pre-receive hook
# ------------------------------------------------------------------------------
while read oldrev newrev refname; do
  # # Debug payload
  # echo -e "${oldrev} ${newrev} ${refname}\n"

  # ----------------------------------------------------------------------------
  # Get the list of all the commits
  # ----------------------------------------------------------------------------

  # Check if a zero sha
  if [ "${oldrev}" = "${zero_commit}" ]; then
    # List everything reachable from newrev but not any heads
    span=`git rev-list $(git for-each-ref --format='%(refname)' refs/heads/* | sed 's/^/\^/') ${newrev}`
  else
    span=`git rev-list ${oldrev}..${newrev}`
  fi

  # ----------------------------------------------------------------------------
  # Iterate over all commits in the push
  # ----------------------------------------------------------------------------
  for sha1 in ${span}; do
    # Use extended regex to search for a match
    match=`git diff-tree -r -p --no-color --no-commit-id --diff-filter=d ${sha1} | grep -nE "(${regex})"`

    # Verify its not empty
    if [ "${match}" != "" ]; then
      # # Debug match
      # echo -e "${match}\n"

      found=$((${found} + 1))
    fi
  done
done

# ------------------------------------------------------------------------------
# Verify count of found errors
# ------------------------------------------------------------------------------
if [ ${found} -gt 0 ]; then
  # Found errors, exit with error
  echo "[POLICY BLOCKED] You're trying to commit a password, token, or confidential information"
  exit 1
else
  # No errors found, exit with success
  exit 0
fi

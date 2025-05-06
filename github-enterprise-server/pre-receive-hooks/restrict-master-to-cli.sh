#!/bin/bash
#
# This hook restricts changes on the default branch to disallow the Web UI blob editor
#
DEFAULT_BRANCH=$(git symbolic-ref HEAD)
while read -r oldrev newrev refname; do
  if [[ "${refname}" != "${DEFAULT_BRANCH:=refs/heads/master}" ]]; then
    continue
  else
    if [[ "${GITHUB_VIA}" = 'blob#save' ]]; then
      echo "Changes to the default branch must be made by cli. Web UI edits are not allowed."
      exit 1
    else
      continue
    fi
  fi
done

#!/bin/bash
#
# This hook restricts changes on the default branch to those made with the GUI Pull Request Merge button, or the Pull Request Merge API.
#
DEFAULT_BRANCH=$(git symbolic-ref HEAD)
while read -r oldrev newrev refname; do
  if [[ "${refname}" != "${DEFAULT_BRANCH:=refs/heads/master}" ]]; then
    continue
  else
    if [[ "${GITHUB_VIA}" != 'pull request merge button' && \
          "${GITHUB_VIA}" != 'pull request merge api' ]]; then
      echo "Changes to the default branch must be made by Pull Request. Direct pushes, edits, or merges are not allowed."
      exit 1
    else
      continue
    fi
  fi
done

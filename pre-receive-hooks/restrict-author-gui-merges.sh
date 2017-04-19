#!/bin/bash
#
# This hook restricts changes on the default branch to those made with the GUI Pull Request Merge button, or the Pull Request Merge API.
#
DEFAULT_BRANCH=$(git symbolic-ref HEAD)
while read -r oldrev newrev refname; do
  if [[ "${refname}" != "${DEFAULT_BRANCH:=refs/heads/master}" ]]; then
    exit 0
  else
    if [[ "${GITHUB_VIA}" != 'pull request merge button' && \
          "${GITHUB_VIA}" != 'pull request merge api' ]]; then
      echo "Changes to the default branch must be made by Pull Request. Direct pushes, edits, or merges are not allowed."
      exit 1
    else
      AUTHOR_COUNT=$(git log ${DEFAULT_BRANCH}..${newrev} --author="${GITHUB_USER_LOGIN}" --format='%an %cn' | wc -l)
      echo "Found ${AUTHOR_COUNT} commits"
      echo "$oldrev"
      echo "$GITHUB_USER_LOGIN"
      if (( ${AUTHOR_COUNT} == 0 )); then
        # No commits containing the current author
        exit 0
      else
        echo "Merging restricted on this branch. Author of commits cannot merge." 
        echo "Found the following commits by author ${GITHUB_USER_LOGIN}"
        echo -e $(git log ${DEFAULT_BRANCH}..${newrev} --author="${GITHUB_USER_LOGIN}")
        # --format='%an %h'
        exit 1
      fi
    fi
  fi
done

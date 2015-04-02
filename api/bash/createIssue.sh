#!/bin/bash

. plumbing.sh

# $1 = username/repo
# $2 = issue details, in JSON
createIssue()
{
  callAPI "repos/$1/issues" -d "$2"
}

createIssue "$@"
#!/usr/bin/env bash

DOMAIN="https://api.github.com"
source ~/projects/github_bash_project/.privateVariables.sh

# Assigning Arguments
whichMethod=$1
username="$2"
label_state_or_repo_name=$3
is_private=$4

function fetchIssuesWhereIAmAssignedWithLabel {
  response=$(curl --silent ${DOMAIN}/search/issues?q=+label:${label_state_or_repo_name}+assignee:${username}+state:open&sort=created&order=asc)
  echo "$response"
}

function fetchNotificationsByRepo {
  response=$(curl -u ${TOKEN}:x-oauth-basic ${DOMAIN}/repos/${username}/${label_state_or_repo_name}/notifications)
  echo "$response"
}

function fetchRepoComments {
  response=$(curl --silent ${DOMAIN}/repos/${username}/${label_state_or_repo_name}/comments)
  echo "$response"
}

function createNewRepo {
  body="{\"name\":\"${label_state_or_repo_name}\",\"description\":\"$username\",\"private\":${is_private},\"has_issues\":true,\"has_wiki\":true,\"has_downloads\":false}"
  response=$(curl --silent -X POST -u ${TOKEN}:x-oauth-basic ${DOMAIN}/user/repos -d ${body})
  echo "$response"
}

# Determining Which Method To Call Based On Command Line Arguments
if [ $whichMethod == "assigned"  ]
  then fetchIssuesWhereIAmAssignedWithLabel
elif [ $whichMethod == "notifications" ]
  then fetchNotificationsByRepo
elif [ $whichMethod == "comments" ]
  then fetchRepoComments
elif [ $whichMethod == "new_repo" ]
  then createNewRepo
else
  echo invalid method name
fi

#!/usr/bin/env bash

#
# Git Block Outdated Clients pre-receive hook
#
# Minimum required version of GHES: 2.22
# This is an implementation of a pre-receive hook for GHES that checks if the current version from the
# user is older than the current version.
#
# If the version is outdated it prints a message encouraging the user to update the client. However if this
# version has a minor diff greater than max_minor_diff the hook fails and
# the user cannot push the changes. You can also block specific versions by adding them to the
# block_list.
#
# Test this locally setting $GIT_USER_AGENT. ex. GIT_USER_AGENT=git/2.2.23 and exporting it.
# Also add to the $GH_TOKEN a personal access token for adding more authentication requests on getting the version
# if you want it dynamically:
# ```
# $ GIT_USER_AGENT=git/2.2.23
# $ GH_TOKEN=token
# $ export GH_TOKEN
# $ export GIT_USER_AGENT
# $ sh git_hook_outdated_clients.sh
# ```
#
# Edit this variables to set the policy for the git version
#
# max_minor_diff: the number of git versions allowed from the latest one.
# block_list: a list containing specific versions that are blocked by policy
max_minor_diff=3
block_list=(
)

# Edit this variables to get the right version to compare as latest
# latest_version: add the latest version to check or leave it empty to let the script get it dynamically
# authentication: provide a PAT on the environment if you want to execute the request to get the version without triggering the rate limit.
# If you don't provide the latest version we strongly recommend to add a GH_TOKEN to the environment. It requires jq as dependency
latest_version=""
authentication=$GH_TOKEN

DEBUG=1

function block_version {
  echo "#########################################"
  echo "##     Outdated git version $1     ##"
  echo "#########################################"
  echo ""
  echo "Update the git version to a newest one: https://git-scm.com/downloads"

  exit 1;
}

#################################
# Parse the version from the user
# agent
#################################
user_version=$GIT_USER_AGENT
if [[ $user_version =~ [0-9]+\.[0-9]+\.[0-9]+ ]]; then
  version=${BASH_REMATCH[0]}
  echo "Current git version: $version"
else
  echo "The user agent used is not supported as it doesn't provide the version it is using"
  exit 1;
fi

#################################
# Check if the version belongs to
# the block list
#################################
for i in "${block_list[@]}"
do
  if [ "$i" == "$version" ]; then
    echo "The version $i is blocked by policy for security reasons. Please update"
    block_version "$version"
  fi
done

#################################
# Get the latest version from an
# external source if not available
# and validate it
#################################
if [ "$latest_version" == "" ]; then
  latest_version=$(curl -s -X GET -H "Authorization: token $authentication" https://api.github.com/repos/git/git/tags \
    | jq ".[0].name")
    if [[ $latest_version =~ [0-9]+\.[0-9]+\.[0-9]+ ]]; then
      latest_version=${BASH_REMATCH[0]}
    else
      echo "Something went wrong getting the latest version. Try it again in a few moments"
      exit 1;
    fi
fi

if ! [[ $latest_version =~ [0-9]+\.[0-9]+\.[0-9]+ ]]; then
  echo "The latest version $latest_version doesn't match the version pattern. Review the parameter latest_version and
  add a version following semantic versioning"
  exit 1;
fi

echo "Latest certified git version: $latest_version"
IFS="." read -r -a version_match <<< "$latest_version"
latest_major="${version_match[0]}"
latest_minor="${version_match[1]}"

#################################
# Parse the versions
#################################
IFS="." read -r -a version_match <<< "$version"
major="${version_match[0]}"
minor="${version_match[1]}"

if [ $DEBUG -eq 0 ]; then
  echo "
  Current version
  =====================
  Major: $major
  Minor: $minor

  Latest version
  =====================
  Major: $latest_major
  Minor: $latest_minor
  "
fi

#################################
# Check for the version policies
#################################
# Major versions should be always updated if there is a new one
if [ "$major" != "$latest_major" ]; then
  block_version "$version"
fi

# Minor versions can be checked by max_minor_diff
allowed_minor=$((minor + max_minor_diff))
if [ "$allowed_minor" -lt "$latest_minor" ]; then
  block_version "$version"
fi

exit 0;

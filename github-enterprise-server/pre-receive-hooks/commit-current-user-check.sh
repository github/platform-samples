#!/usr/bin/env bash
#
# Pre-receive hook that will reject all pushes where author or committer are not the current user.
#
# Pre-requisites for the users.
# They must have:
# * git config --global user.email set to an email address
# * That email address must be set as a public email address in GitHub Enterprise
# * git config --global user.name must be set to GitHub Enterprise login name

# If we are on the GitHub Web interface then we don't need to bother to validate the commit user
if [[ "${GITHUB_VIA}" == "pull request merge button" ]] || \
   [[ "${GITHUB_VIA}" == "blob edit" ]]; then
   exit 0
fi

# Set up a user token (attached to a non expiring account) that can just read public email addresses.
TOKEN=USER:TOKEN

# We set the address of the GHE Instance here
GHE_URL=https://GHE-INSTANCE

GITHUB_USER_EMAIL=`curl -s -k -u ${TOKEN} ${GHE_URL}/api/v3/users/${GITHUB_USER_LOGIN} | grep email | sed 's/  \"email\"\: \"//' | sed 's/\",//'`

if echo "${GITHUB_USER_EMAIL}" | grep "null,"
then
   echo -e "ERROR: User does not have public email address set in GitHub Enterprise."
   echo "Please set public email address at ${GHE_URL}/settings/profile."
   exit 1
fi

zero_commit="0000000000000000000000000000000000000000"

# Do not traverse over commits that are already in the repository 
# (e.g. in a different branch) 
# This prevents funny errors if pre-receive hooks got enabled after some 
# commits got already in and then somebody tries to create a new branch 
# If this is unwanted behavior, just set the variable to empty 

excludeExisting="--not --all" 
 
while read oldrev newrev refname; do 
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
        AUTHOR_USER=`git log --format=%an -n 1 ${COMMIT}`
        AUTHOR_EMAIL=`git log --format=%ae -n 1 ${COMMIT}`
        COMMIT_USER=`git log --format=%cn -n 1 ${COMMIT}`
        COMMIT_EMAIL=`git log --format=%ce -n 1 ${COMMIT}`
         
        if [[ ${AUTHOR_USER} != ${GITHUB_USER_LOGIN} ]]; then
            echo -e "ERROR: Commit author (${AUTHOR_USER}) does not match the current GitHub Enterprise user (${GITHUB_USER_LOGIN})"
            exit 20
        fi
        
        if [[ ${COMMIT_USER} != ${GITHUB_USER_LOGIN} ]]; then
            echo -e "ERROR: Commit User (${COMMIT_USER}) does not match the current GitHub Enterprise user (${GITHUB_USER_LOGIN})"
            exit 30
        fi
        
        if [[ ${AUTHOR_EMAIL} != ${GITHUB_USER_EMAIL} ]]; then
            echo -e "ERROR: Commit author's email (${AUTHOR_EMAIL}) does not match the current GitHub Enterprise user's email (${GITHUB_USER_EMAIL})"
            exit 40
        fi
        
        if [[ ${COMMIT_EMAIL} != ${GITHUB_USER_EMAIL} ]]; then
            echo -e "ERROR: Commit user's email (${COMMIT_EMAIL}) does not match the current GitHub Enterprise user's email (${GITHUB_USER_EMAIL})"
            exit 50
        fi
    done 
done 

exit 0

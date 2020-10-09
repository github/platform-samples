#!/bin/bash
# Replace the "xxxxx" with the required values
# Author: @ppremk

# Script to create GitHub Teams in bulk on GitHub.com Organization
# PAT Tokens needs to have the correct scope to be able to create teams in an organization
# Teams are added as an Array. Teams are created as stand alone teams. Team relationship is not defined

# To run the script:
#
# - Update VARS section in script
# - chmod +x script.sh
# - ./script.sh

# VARS
ORGNAME="xxxx" 
PATTOKEN="xxxx"
TEAMS=("team-name-1" "team-name-2")

echo "Bulk creating teams in:"
echo $ORGNAME

for i in "${TEAMS[@]}"
do
curl --request POST \
  --url "https://api.github.com/orgs/$ORGNAME/teams" \
  --header "accept: application/vnd.github.v3+json" \
  --header "authorization: Bearer ${PATTOKEN}" \
  --header "content-type: application/json" \
  --data "{\"name\": \"$i\", \"privacy\": \"closed\" }"
done

if [ $ERROR_CODE -ne 0 ]; then
  echo "Team creation failed! Please verify validity of supplied configurations."
  exit 1
else
  echo "Teams succesfully created!"
fi



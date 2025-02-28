#!/bin/sh
#/
#/ NAME:
#/ update-user-and-team-dn-for-ldap - For a GitHub Enterprise instance using LDAP,
#/ reads in a `users.txt` files and `teams.txt` files to change the distinguished
#/ name (DN) of each user and team to your new LDAP provider's DN. See PRE-REQUISITES
#/ below for more information on creating and formatting those files.
#/
#/ AUTHOR: @IAmHughes
#/
#/ DESCRIPTION:
#/ For a GitHub Enterprise instance using LDAP, reads in a `users.txt` files and
#/ `teams.txt` files to change the distinguished name (DN) of each user and team to
#/ your new LDAP provider's DN. See PRE-REQUISITES below for more information on
#/ creating and formatting those files.
#/
#/ PRE-REQUISITES:
#/ Before running this script, you must create a Personal Access Token (PAT)
#/ at https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/
#/ with the permissions <repo>, <admin:org>, <user>, and <site_admin> scopes. Read more
#/ about scopes here: https://developer.github.com/apps/building-oauth-apps/scopes-for-oauth-apps/
#/
#/ Once created, you must export your PAT as an environment variable
#/ named <GITHUB_TOKEN>.
#/
#/   - Exporting PAT as GITHUB_TOKEN
#/   $ export GITHUB_TOKEN=abcd1234efg567
#/
#/ Additionally you will need to set the $API_ROOT at the top of the script to
#/ your instance of GitHub Enterprise.
#/  - _i.e._: https://MyGitHubEnterprise.com/api/v3
#/
#/ Finally, you need to set up your `users.txt` and `teams.txt` files in the directory you
#/ will run the script from. They need to be in the format of <user>:<newDN> or <team>:<newDN>
#/ where <user> or <team> is the respective username or team name in GitHub that should map to
#/ the new DN, <newDN>, for that user or team in the new LDAP provider.
#/ 
#/ - Sample users.txt file:
#/ <user1>:<newDN>
#/ <another_user>:<newDN>
#/ <my_other_user>:<newDN>
#/
#/ - Sample teams.txt file:
#/ <team1>:<newDN>
#/ <my_team>:<newDN>
#/ <another_team>:<newDN>
#/
#/ API DOCUMENTATION:
#/ All documentation can be found at https://developer.github.com/v3/

########
# VARS #
########
API_ROOT="https://<your-domain>/api/v3"
GITHUB_TOKEN=""
USER_MAPPING_FILE="./users.txt"
TEAM_MAPPING_FILE="./teams.txt"

#####################
# PROCESS USER FILE #
#####################

# Read each line of text file, including last line
while read -r line || [[ -n "${line}" ]]; do

  # Error Handling - Check if line is empty
  if [[ -z ${line} ]]; then
    echo "Line is empty, exiting script."
    continue
  fi

  # Get Username
  username=$(echo ${line} | awk -F':' {'print $1'})

  # Get DN
  ldap_dn=$(echo ${line} | awk -F':' {'print $2'})

  # Error Handling - Verify Username and LDAP DN were found
  if [[ -z ${username} ]]; then
    echo "Username not found. Username was set to: ${username}"
    continue
  fi

  if [[ -z ${ldap_dn} ]]; then
    echo "LDAP DN not found. LDAP DN was set to: ${ldap_dn} for Username: ${username}"
  fi

  # Error Handling - Verify user exists in GitHub Enterprise
  # Curl options used - more info [here](http://www.mit.edu/afs.new/sipb/user/ssen/src/curl-7.11.1/docs/curl.html)
  # -s = silent
  # -o = output - we don't want the output other than the status code, so send to /dev/null
  # -I = fetch header only
  # -w = The option we want to write-out, so we specify %{http_code}
  response="$(curl -s -o /dev/null -I -w "%{http_code}" --request GET \
    --url ${API_ROOT}/users/${username} \
    --header "authorization: Bearer ${GITHUB_TOKEN}")"

  # Generate body for PATCH curl call below
  function generate_patch_data_for_users()
  {
    cat <<EOF
      {
        "ldap_dn": "$ldap_dn"
      }
EOF
  }

  # User Exists, call API to Update LDAP Mapping
  if [[ response -eq 200 ]]; then
    curl -s --request PATCH \
      --url ${API_ROOT}/admin/ldap/users/${username}/mapping \
      --header "authorization: Bearer ${GITHUB_TOKEN}" \
      --header "content-type: application/json" \
      --data "$(generate_patch_data)"
  fi
done < "${USER_MAPPING_FILE}"

#####################
# PROCESS TEAM FILE #
#####################

# Read each line of text file, including last line
while read -r line || [[ -n "${line}" ]]; do

  # Error Handling - Check if Line is Empty
  if [[ -z ${line} ]]; then
    echo "Line is empty, exiting script."
    continue
  fi

  # Get Team ID
  team_id=$(echo ${line} | awk -F':' {'print $1'})
  # Get DN
  ldap_dn=$(echo ${line} | awk -F':' {'print $2'}

  # Error Handling - Verify Team ID and LDAP DN were found
  if [[ -z ${team_id} ]]; then
    echo "Team not found. Team ID was set to: ${team_id}"
    continue
  fi

  if [[ -z ${ldap_dn} ]]; then
    echo "LDAP DN not found. LDAP DN was set to: ${ldap_dn} for Team: ${team_id}"
  fi

  # Error Handling - Verify team exists in GitHub Enterprise
  # Curl options used - more info [here](http://www.mit.edu/afs.new/sipb/user/ssen/src/curl-7.11.1/docs/curl.html)
  # -s = silent
  # -o = output - we don't want the output other than the status code, so send to /dev/null
  # -I = fetch header only
  # -w = The option we want to write-out, so we specify %{http_code}
  response="$(curl -s -o /dev/null -I -w "%{http_code}" --request GET \
    --url ${API_ROOT}/teams/${team_id} \
    --header 'accept: application/vnd.github.hellcat-preview+json' \
    --header "authorization: Bearer ${GITHUB_TOKEN}")"

  # Generate body for PATCH curl call below
  function generate_patch_data_for_teams()
  {
    cat <<EOF
      {
        "ldap_dn": "$ldap_dn"
      }
EOF
  }

  # Team Exists, call API to Update LDAP Mapping
  if [[ response -eq 200 ]]; then
    curl -s --request PATCH \
      --url ${API_ROOT}/admin/ldap/teams/${team_id}/mapping \
      --header 'accept: application/vnd.github.hellcat-preview+json' \
      --header "authorization: Bearer ${GITHUB_TOKEN}" \
      --header "content-type: application/json" \
      --data "$(generate_patch_data)"
  fi
done < "${TEAM_MAPPING_FILE}"

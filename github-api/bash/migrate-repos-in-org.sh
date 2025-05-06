#!/usr/bin/bash

#################################################
# Migrate All repos in One Org to a Master Org  #
# Used to help consolidate users Orgs           #
# Can run in debug mode to show list of actions #
#                                               #
# @admiralAwkbar                                #
#################################################

#
# Legend:
# This script is used to migrate repos from one organization
# to a master organization. This is done in org consolidations.
# It will transfer ownership to the new org. It can also set
# teams access in master org when the transfer is complete.
# You just need to set the teams ids in the script
# To run the script:
#
# - Update variables section in script
# - chmod +x script.sh
# - export GITHUB_TOKEN=YourGitHubTokenWithAccess 
# - ./script.sh UsersOrg
#
# Script can be ran in debug mode as well to show what repos
# will be migrated
#

##############
# Debug Flag #
##############
DEBUG=1                             # Debug Flag 0=execute 1=report

########
# VARS #
########
ORIG_ORG=$1                         # Name of the Original GitHub Organization
UPDATE_TEAMS=1                      # Update Teams access 0=skip 1=execute
MASTER_ORG=''                       # Name of the master Organization
#GITHUB_TOKEN=''                     # Token to authenticate into GitHub
GITHUB_URL="https://api.github.com" # URL to GitHub
READ_TEAM=''                        # ID of the GitHub team with read access
WRITE_TEAM=''                       # Team to add with write access to the repos
ADMIN_TEAM=''                       # ID of the GitHub team with Admin access

#################################
# Vars Set During Run of Script #
#################################
ORIG_ORG_REPOS=                     # Array of all the repositories in Organization
TEAM_IDS="$READ_TEAM,$ADMIN_TEAM"   # String of all team ids to add to repos
ERROR_COUNT='0'                     # Total errors found

################################################################################
####################### SUB ROUTINES BELOW #####################################
################################################################################
################################################################################
#### Function CheckVars ########################################################
CheckVars()
{
   # Validate we have Original Org name
   if [[ -z $ORIG_ORG ]]; then
      echo "ERROR: No Original Organization given!"
      echo $0 <OriginalOrganizationName>
      exit 1
   fi

   # Validate we have Master Org name
   if [[ -z $MASTER_ORG ]]; then
      echo "ERROR: No MASTER Organization given!"
      echo "Please update scripts internal Variables!"
      exit 1
   fi

   # Validate we have a token to connect
   if [[ -z $GITHUB_TOKEN ]]; then
      echo "ERROR: No GitHub Token given!"
      echo "Please update scripts internal Variables! Or set env var: export GITHUB_TOKEN=YourToken"
      exit 1
   fi

   ################################
   # Check if were updating teams #
   ################################
   if [ $UPDATE_TEAMS -eq 0 ]; then
      echo "Skippinig the update of team permissions"
   else
      # Validate we have a team to grant read access
      if [[ -z $READ_TEAM ]]; then
         echo "ERROR: No Read access team given!"
         echo "Please update scripts internal Variables!"
         exit 1
      fi

      # Validate we have a team to grant write access
      if [[ -z $WRITE_TEAM ]]; then
         echo "ERROR: No Write access team given!"
         echo "Please update scripts internal Variables!"
         exit 1
      fi

      # Validate we have a team to grant admin access
      if [[ -z $ADMIN_TEAM ]]; then
         echo "ERROR: No Admin access team given!"
         echo "Please update scripts internal Variables!"
         exit 1
      fi
   fi
}
################################################################################
#### Function GetTeamIds #######################################################
GetTeamIds()
{
   #################################################
   # Need to get the team id from team name passed #
   #################################################
   REGEX='^[0-9]+$'
   # Check if team was passed as number
   if [[ $WRITE_TEAM =~ $REGEX ]]; then
      echo "Team ID passed, adding to list"
      TEAM_IDS+=",$WRITE_TEAM"
   else
      echo "Need to convert TeamName into ID"
      TEAM_RESPONSE=$(curl --request GET \
         --url $GITHUB_URL/orgs/$ORIG_ORG/teams \
         --header 'accept: application/vnd.github.hellcat-preview+json' \
         --header "authorization: token $GITHUB_TOKEN")

      # Get the team id
      get_team_id()
      {
         echo ${TEAM_RESPONSE} | base64 --decode | jq -r ${1}
         #echo ${TEAM_RESPONSE} | base64 --decode --ignore-garbage | jq -r ${1} # Need ignore garbae on windows machines
      }

      # Get the id of the team
      TEAM_ID=$(get_team_id '.id')
      echo "TeamId:[$TEAM_ID]"
      TEAM_IDS+=",$TEAM_ID"
      # Reset the global to the id
      WRITE_TEAM=$TEAM_ID
   fi
}
################################################################################
#### Function UpdateTeamPermission #############################################
UpdateTeamPermission()
{
   # need to add the teams permissions to the repo
   REPO_TO_UPDATE_PERMS=$1
   # https://developer.github.com/v3/teams/#edit-team
   # PUT /teams/:team_id/repos/:owner/:repo

   ###################################
   # Update the Read Permission Team #
   ###################################
   echo "-----------------------------------------------------"
   echo "Setting Read Team Permissions"
   curl -s --request PUT \
      --url $GITHUB_URL/teams/$READ_TEAM/repos/$MASTER_ORG/$REPO_TO_UPDATE_PERMS \
      --header "authorization: Bearer $GITHUB_TOKEN" \
      --header 'content-type: application/json' \
      --header 'application/vnd.github.hellcat-preview+json' \
      --data  \"{\"permission\": \"pull\"}\"

   ########################
   # Check for any errors #
   ########################
   if [ $? -ne 0 ]; then
      echo "Error! Failed to set permission"
      ((ERROR_COUNT++))
   fi

   ####################################
   # Update the Write Permission Team #
   ####################################
   echo "-----------------------------------------------------"
   echo "Setting Write Team Permissions"
   curl -s --request PUT \
      --url $GITHUB_URL/teams/$WRITE_TEAM/repos/$MASTER_ORG/$REPO_TO_UPDATE_PERMS \
      --header "authorization: Bearer $GITHUB_TOKEN" \
      --header 'content-type: application/json' \
      --header 'application/vnd.github.hellcat-preview+json' \
      --data  \"{\"permission\": \"push\"}\"

   ########################
   # Check for any errors #
   ########################
   if [ $? -ne 0 ]; then
      echo "Error! Failed to set permission"
      ((ERROR_COUNT++))
   fi

   ####################################
   # Update the Admin Permission Team #
   ####################################
   echo "-----------------------------------------------------"
   echo "Setting Admin Team Permissions"
   curl -s --request PUT \
      --url $GITHUB_URL/teams/$ADMIN_TEAM/repos/$MASTER_ORG/$REPO_TO_UPDATE_PERMS \
      --header "authorization: Bearer $GITHUB_TOKEN" \
      --header 'content-type: application/json' \
      --header 'application/vnd.github.hellcat-preview+json' \
      --data  \"{\"permission\": \"admin\"}\"

   ########################
   # Check for any errors #
   ########################
   if [ $? -ne 0 ]; then
      echo "Error! Failed to set permission"
      ((ERROR_COUNT++))
   fi
}
################################################################################
#### Function GetOrigOrgRepos ##################################################
GetOrigOrgRepos()
{
   ##############################
   # Get response with all info #
   ##############################
   echo "-----------------------------------------------------"
   echo "Gathering all repos from Original Organization:[$ORIG_ORG]"
   ORIG_ORG_RESPONSE=$(curl -s --request GET \
      --url $GITHUB_URL/orgs/$ORIG_ORG/repos \
      --header "authorization: Bearer $GITHUB_TOKEN" \
      --header 'content-type: application/json')

   #######################################################
   # Loop through list of repos in original organization #
   #######################################################
   echo "-----------------------------------------------------"
   echo "Parsing repo names from Original Organization:"
   for orig_repo in $(echo "${ORIG_ORG_RESPONSE}" | jq -r '.[] | @base64');
   do
      # Pull the name of the repo out
      get_orig_repo_name()
      {
         echo ${orig_repo} | base64 --decode | jq -r ${1}
         #echo ${orig_repo} | base64 --decode --ignore-garbage | jq -r ${1} # Need ignore garbage on windows machines
      }

      # Get the name of the repo
      ORIG_REPO_NAME=$(get_orig_repo_name '.name')
      echo "Name:[$ORIG_REPO_NAME]"
      ORIG_ORG_REPOS+=($ORIG_REPO_NAME)
   done
}
################################################################################
#### Function MigrateRepos #####################################################
MigrateRepos()
{
   ########################################
   # Migrate all the repos to the new org #
   ########################################
   echo "-----------------------------------------------------"
   echo "Migrating Reposities to master Organization:[$MASTER_ORG]"
   for new_repo in ${ORIG_ORG_REPOS[@]};
   do
      #######################################
      # Call the single repo to be migrated #
      #######################################
      if [ $DEBUG -eq 0 ]; then
         if [ $UPDATE_TEAMS -eq 0 ]; then
            ##########################################
            # Migrating repos without updating teams #
            ##########################################
            echo "-----------------------------------------------------"
            echo "Skipping updating teams"
            echo "Migrating Repo:[$new_repo] to:[$MASTER_ORG/$new_repo]"
            #####################################
            # Call GitHub =API to transfer repo #
            #####################################
            curl -s --request POST \
               --url $GITHUB_URL/repos/$ORIG_ORG/$new_repo/transfer \
               --header "authorization: Bearer $GITHUB_TOKEN" \
               --header 'content-type: application/json' \
               --header 'application/vnd.github.nightshade-preview+json' \
               --data  \"{\"new_owner\": \"$MASTER_ORG\"}\"

            ########################
            # Check for any errors #
            ########################
            if [ $? -ne 0 ]; then
               echo "Error! Failed to migrate repo"
               ((ERROR_COUNT++))
            fi
         else
            ######################################
            # Migrating repos and updating teams #
            ######################################
            echo "-----------------------------------------------------"
            echo "Migrating Repo:[$new_repo] to:[$MASTER_ORG/$new_repo]"
            #####################################
            # Call GitHub =API to transfer repo #
            #####################################
            curl -s --request POST \
               --url $GITHUB_URL/repos/$ORIG_ORG/$new_repo/transfer \
               --header "authorization: Bearer $GITHUB_TOKEN" \
               --header 'content-type: application/json' \
               --header 'application/vnd.github.nightshade-preview+json' \
               --data  \"{\"new_owner\": \"$MASTER_ORG\", \"team_ids\": [ $TEAM_IDS ]}\"

            ########################
            # Check for any errors #
            ########################
            if [ $? -ne 0 ]; then
               echo "Error! Failed to migrate repo"
               ((ERROR_COUNT++))
            fi
            
            ###########################
            # Update Team permissions #
            ###########################
            UpdateTeamPermission $new_repo
         fi
      else
         # Debug loop to print results
         echo "DEBUG: Would have moved:[$new_repo] to:[$MASTER_ORG/$new_repo]"
      fi
   done
}
################################################################################
#### Function Footer ###########################################################
Footer()
{
   ####################
   # Print the footer #
   ####################
   echo "-----------------------------------------------------"
   echo "the script has completed"
   exit $ERROR_COUNT
}
################################################################################
#### Function Header ###########################################################
Header()
{
   #####################
   # Print Header Info #
   #####################
   echo "-----------------------------------------------------"
   echo "-----------------------------------------------------"
   echo "----- Migrate Repos from user Org to Master Org -----"
   echo "-----------------------------------------------------"
   echo "-----------------------------------------------------"
   echo ""
   echo "Migrating All Repositories from Org:[$ORIG_ORG]"
   echo "Moving all Repositories to Org:[$MASTER_ORG]"
   ##############
   # Debug info #
   ##############
   if [ $DEBUG -eq 1 ]; then
      echo "Running in DEBUG mode! Will only report Repositories that will be migrated"
   else
      echo "Running in Execute mode! Will migrate all repositories"
   fi
   #############
   # Team Info #
   #############
   if [ $UPDATE_TEAMS -eq 1 ]; then
      echo "Updating Repositories teams when migrating"
   else
      echo "No teams will be assigned during the migration process"
   fi
   echo ""
}
################################################################################
################################################################################
############################## MAIN ############################################
################################################################################
################################################################################

#######################################################
# Checking that all variables were passed in properly #
#######################################################
CheckVars

########################################
# Get all repositories in Original Org #
########################################
GetOrigOrgRepos

####################################################
# Get a list of all teamIds for the repo migration #
####################################################
GetTeamIds

###############################################
# Migrate Repositories to master organization #
###############################################
MigrateRepos

####################
# Print the footer #
####################
Footer

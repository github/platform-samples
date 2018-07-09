#!/bin/bash

#########################################
# Collision detection script to verify  #
# That all Repos in an Org do NOT exist #
# in the master Organization            #
#                                       #
# @admiralAwkbar                        #
#########################################

#
# Legend:
# This script is used to see if repo names from one organization
# are found in another ogranization. This is helpful
# when your consolidating organizations into a single Org
#
# To run the script:
# - chmod +x script.sh
# - export GITHUB_TOKEN=YourGithubTokenWithAccessToBothOrgs
# - ./script OriginalOrg MasterOrg
#
# The script will come back with a list of any repos that have a 
# name collision that will cause errors in a migration process
# 


########
# VARS #
########
ORIG_ORG=$1          	# Name of the users GitHub Organization
MASTER_ORG=$2		      # Name of the master Organization
GITHUB_TOKEN=''      	# Token to authenticate into GitHub

######################################
# Will be set when the script is ran #
######################################
ORIG_ORG_REPOS=         # Array of all the repositories in Organization
MASTER_ORG_REPOS=  	   # Array of all the repositories in Organization
COLLISION_REPOS=	      # Repos that will have a collision

################################################################################
######################## SUB ROUTINES BELOW ####################################
################################################################################
################################################################################
#### Sub Routine ValidateInput #################################################
ValidateInput()
{
   ###########################################
   # Need to make sure we have all varaibles #
   ###########################################
   # Validate we have Original Organization Name
   if [[ -z $ORIG_ORG ]]; then
      echo "ERROR: No Original Organization given!"
      echo $0 <Original_Organization_Name> <Master_Organization_Name>
      exit 1
   fi

   # Validate we have Master Organization Name
   if [[ -z $MASTER_ORG ]]; then
      echo "ERROR: No Master Organization given!"
      echo $0 <Original_Organization_Name> <Master_Organization_Name>
      exit 1
   fi

   # Validate we have a token to connect to GitHub
   if [[ -z $GITHUB_TOKEN ]]; then
      echo "ERROR: No GitHub Token given!"
      echo "Please update script with GitHub token or place token in the environment"
      echo "Example: Comment out line GITHUB_TOKEN='' and then export GITHUB_TOKEN=YourToken"
      echo $0 <Original_Organization_Name> <Master_Organization_Name>
      exit 1
   fi
}
################################################################################
#### Sub Routine Header ########################################################
Header()
{
   ###############################
   # Print the basic header info #
   ###############################
   echo "-----------------------------------------------------"
   echo "------ GitHub Repo Collision Detection Script -------"
   echo "-- Validating Repo name not found inside master Org -"
   echo "-----------------------------------------------------"
   echo ""
   echo "Original Organization:[$ORIG_ORG]"
   echo "Master Organization:[$MASTER_ORG]"
   echo ""
}
################################################################################
#### Sub Routine GetOrigOrgInfo ################################################
GetOrigOrgInfo()
{
   ####################################
   # Get all repositories in User Org #
   ####################################
   echo "-----------------------------------------------------"
   echo "Gathering all repos from Original Organization:[$ORIG_ORG]"
   ORIG_ORG_RESPONSE=$(curl -s --request GET \
      --url https://api.github.com/orgs/$ORIG_ORG/repos \
      --header "authorization: Bearer $GITHUB_TOKEN" \
      --header 'content-type: application/json')

   #######################################################
   # Loop through list of repos in original organization #
   #######################################################
   echo "-----------------------------------------------------"
   echo "Parsing repo names from Original Organization:"
   for orig_repo in $(echo "${ORIG_ORG_RESPONSE}" | jq -r '.[] | @base64');
   do
      get_orig_repo_name()
      {
         echo ${orig_repo} | base64 --decode | jq -r ${1}
      }

      # Get the name of the repo
      ORIG_REPO_NAME=$(get_orig_repo_name '.name')
      echo "Name:[$ORIG_REPO_NAME]"
      ORIG_ORG_REPOS+=($ORIG_REPO_NAME)
   done
}
################################################################################
#### Sub Routine GetMasterOrgInfo ##############################################
GetMasterOrgInfo()
{
   ######################################
   # Get all repositories in MASTER Org #
   ######################################
   echo "-----------------------------------------------------"
   echo "Gathering all repos from Master Organization:[$MASTER_ORG]"
   MASTER_ORG_RESPONSE=$(curl -s --request GET \
      --url https://api.github.com/orgs/$MASTER_ORG/repos \
      --header "authorization: Bearer $GITHUB_TOKEN" \
      --header 'content-type: application/json')

   #####################################################
   # Loop through list of repos in master organization #
   #####################################################
   echo "-----------------------------------------------------"
   echo "Parsing repo names from Master Organization:"
   for master_repo in $(echo "${MASTER_ORG_RESPONSE}" | jq -r '.[] | @base64');
   do
      get_master_repo_name()
      {
         echo ${master_repo} | base64 --decode | jq -r ${1}
      }

      # Get the name of the repo
      MASTER_REPO_NAME=$(get_master_repo_name '.name')
      echo "Name:[$MASTER_REPO_NAME]"
      MASTER_ORG_REPOS+=($MASTER_REPO_NAME)
   done
}
################################################################################
#### Sub Routine CheckCollisions ###############################################
CheckCollisions()
{
   ############################
   # Check for any collisions #
   ############################
   echo "-----------------------------------------------------"
   echo "Checking for collisions"
   for new_repo in ${ORIG_ORG_REPOS[@]};
   do
      if [[ " ${MASTER_ORG_REPOS[@]} " =~ " ${new_repo} " ]]; then
         # We have found the name of the repo in the master org
         echo "ERROR: Collision detection repo:[$new_repo]"
         COLLISION_REPOS+=($new_repo)
      fi
   done

   ##############################
   # Print the collisions found #
   ##############################
   echo "-----------------------------------------------------"
   echo "COLLISION_REPOS:"
   for repo in ${COLLISION_REPOS[@]};
   do
      echo "$repo"
   done
}
################################################################################
#### Sub Routine Footer ########################################################
Footer()
{
   ###################################################
   # Check to see if we exit with success or failure #
   ###################################################
   echo "-----------------------------------------------------"
   if [ ${#COLLISION_REPOS[@]} -eq 0 ]; then
       echo "No collisions detected"
       exit 0
   else
       echo "ERROR: Collisions detected!"
       exit 1
   fi
}
################################################################################
############################## MAIN ############################################
################################################################################

##################
# Validate input #
##################
ValidateInput

##########
# Header #
##########
Header

####################################
# Get all repositories in User Org #
####################################
GetOrigOrgInfo

######################################
# Get all repositories in MASTER Org #
######################################
GetMasterOrgInfo

##############################################################################
# Check if original is already in master, if so add to COLLISION_REPOS array #
##############################################################################
CheckCollisions

####################
# Print the footer #
####################
Footer

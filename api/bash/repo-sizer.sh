#!/bin/bash

################################################
# Script to Traverse Repo and find Large files #
# Will give report of files over size limit    #
# Will give report of files with               #
# particular extensions                        #
#                                              #
# @AdmiralAwkbar                               #
################################################

#
# Legend:
# To run this script, you just need:
# - chmod +x script.sh
# - ./script.sh <path/to/scan>
#
# Script will scan that directory for size and
# files with extensions that could be ommitted
#

########
# VARS #
########
DIR_TO_SCAN=$1    # Directory to scan for large files
SIZE_LIMIT='100'  # Size in MB to look for
SIZE_LIMIT+="M"   # Add the M to the end for megabytes. Options include k,M,T,P
FILE_TYPES=(".jar" ".war" ".zip" ".gzip" ".obj") # List of file types to find and warn on
ERROR_COUNT='0'   # Total errors found

################################################################################
############################ FUNCTIONS #########################################
################################################################################
################################################################################
#### Function ValidateInput ####################################################
ValidateInput()
{

   ##################################
   # Validate we have a dir to scan #
   ##################################
   if [ $# -lt 1 ]; then
      # Send it to help screen
      echo "ERROR! Please give directory to search for large files"
      echo "Example: $0 /tmp/myRepo"
      echo "-----------------------------------------------------"
      exit 1
   fi
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
   echo "--------------- Repo Size Scanner -------------------"
   echo "-----------------------------------------------------"
   echo "-----------------------------------------------------"
   echo ""
   echo "Scanning Directory:[$DIR_TO_SCAN]"
   echo "Script will scan directory recursively to find files"
   echo "over the size limit:[$SIZE_LIMIT]mb"
   echo "Script will report files over the limit, as well as "
   echo "any files found with the following extensions:"
   for TYPE in "${FILE_TYPES[@]}"; do
      echo "Extension:[$TYPE]"
   done
   echo ""
}
################################################################################
#### Function ValidateDirectory ################################################
ValidateDirectory()
{
   ########################################################
   # Checking that the directory exists and we can see it #
   ########################################################
   echo "-----------------------------------------------------"
   if [ -d "$DIR_TO_SCAN" ]; then
      echo "Found directory, preparing for scan..."
   else
      echo "ERROR! Could not find Directory:[$DIR_TO_SCAN]"
      exit 1
   fi
}
################################################################################
#### Function GetRepoSize ######################################################
GetRepoSize()
{
   ################################
   # Get the size on disk or repo #
   ################################
   echo "-----------------------------------------------------"
   echo "Getting complete size of repository on disk."
   echo "This could take several moments depending on repo size..."
   # Grab the current size of the repository on disk
   SIZE=($(du -sh $DIR_TO_SCAN))

   # Print the size thats cleaned up
   echo "Total size of repository on disk:[$SIZE]"
}
################################################################################
#### Function RunScan ##########################################################
RunScan()
{
   echo "-----------------------------------------------------"
   echo "Running scan of:[$DIR_TO_SCAN]"
   echo "This could take several moments depending on repo size..."

   #############################################
   # Print the list of files that are an issue #
   #############################################
   echo "-----------------------------------------------------"
   echo "---- Files that were found over the size limit:  ----"
   echo "-----------------------------------------------------"
   # Save current IFS
   SAVEIFS=$IFS
   # Change IFS to new line.
   IFS=$'\n'
   OVER_LIMIT=($(find $DIR_TO_SCAN -type f -size +$SIZE_LIMIT -exec du -h {} \; | sort -n))
   # Restore IFS
   IFS=$SAVEIFS
   #################################
   # Check the results of the call #
   #################################
   if [ ${#OVER_LIMIT[@]} -eq 0 ]; then
      echo "0 files found over limit"
   else
      for FILE in "${OVER_LIMIT[@]}"; do
         echo "[$FILE]"
         ((ERROR_COUNT++))
      done
   fi
}
################################################################################
#### Function ScanWhitelist ####################################################
ScanWhitelist()
{
   echo "-----------------------------------------------------"
   echo "Running scan of:[$DIR_TO_SCAN] for file types:"
   echo "This could take several moments depending on repo size..."

   #############################################
   # Print the list of files that are an issue #
   #############################################
   for TYPE in "${FILE_TYPES[@]}"; do
      echo "--------------------------"
      echo "Searching for type:[$TYPE]"
      # Need to load files found into array
      FILES_FOUND=($(find $DIR_TO_SCAN -name "*$TYPE"))
      if [ ${#FILES_FOUND[@]} -eq 0 ]; then
         echo "0 files found"
      else
         for FILE in "${FILES_FOUND[@]}"; do
            echo "Found File:[$FILE]"
            ((ERROR_COUNT++))
         done
      fi
   done
}
################################################################################
#### Function Footer ###########################################################
Footer()
{
   ######################
   # Print Closing Info #
   ######################
   echo "-----------------------------------------------------"
   echo "-----------------------------------------------------"
   if [ $ERROR_COUNT -eq 0 ]; then
      echo "Process Completed Successfully"
      echo "No files over size limit or bad extensions"
      echo "-----------------------------------------------------"
   else
      echo "ERRORS FOUND! COUNT:[$ERROR_COUNT]"
      echo "-----------------------------------------------------"
      exit $ERROR_COUNT
   fi
}
################################################################################
############################## MAIN ############################################
################################################################################

##################
# Validate Input #
##################
ValidateInput $1

###########
# Headers #
###########
Header

#################################
# Validate the Directory Exists #
#################################
ValidateDirectory

#################################
# Get the size of the full repo #
#################################
GetRepoSize

###############
# Check files #
###############
RunScan

#########################
# Check Whitelist files #
#########################
ScanWhitelist

################
# Print Footer #
################
Footer

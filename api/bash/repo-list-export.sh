#!/usr/bin/env bash
#
# set GITHUB_TOKEN to your GitHub or GHE access token
# set GITHUB_API_ENDPOINT to your GHE API endpoint (defaults to https://api.github.com)

if [ -n "$GITHUB_API_ENDPOINT" ]
  then
    url=$GITHUB_API_ENDPOINT
  else
    url="https://api.github.com"
fi

token=$GITHUB_TOKEN

dependency_test()
{
  for dep in curl jq ; do
    command -v $dep &>/dev/null || { echo -e "\n${_error}Error:${_reset} I require the ${_command}$dep${_reset} command but it's not installed.\n"; exit 1; }
  done
}

token_test()
{
  if [ -n "$token" ]
    then
    token_cmd="Authorization: token $token"
  else
    echo "You must set a Personal Access Token to the GITHUB_TOKEN environment variable"
    exit 1
  fi
}

usage()
{
  echo -e "Usage: $0 [options] <orgname>...\n"
  echo "Options:"
  echo " -h | --help                      Help"
  echo ""
}

get_repos()
{
  last_repo_page=$( curl -s --head -H "$token_cmd" "$url/orgs/$org/repos?per_page=100" | sed -nE 's/^Link:.*per_page=100.page=([0-9]+)>; rel="last".*/\1/p' )

  if [ "$last_repo_page" == "" ]
  then
    all_repos=$( curl -s -H "$token_cmd" "$url/orgs/$org/repos?per_page=100" | jq '.[].name' | sed 's/\"//g' )

    total_repos=$( echo $all_repos | sed 's/\"//g' | wc -w | sed 's/ //g' )
    echo "Fetching repository list for '$org' organization on GitHub.com"
    for (( i=1; i<=$total_repos; i++ ))
    do

      repo=$( echo ${all_repos[0]} | cut -f $i -d " " )
      echo "$repo"

    done > repos.txt
    echo "Total # of repositories in "\'$org\'": $total_repos"
    echo "List saved to $org.txt"
  else
    for (( j=1; j<=$last_repo_page; j++ ))
    do
      all_repos=$( curl -s -H "$token_cmd" "$url/orgs/$org/repos?per_page=100&page=$j" | jq '.[].name' | sed 's/\"//g' )

      total_repos=$( echo $all_repos | sed 's/\"//g' | wc -w | sed 's/ //g' )
      echo "Fetching repository list for '$org' organization on GitHub.com"

      for (( i=1; i<=$total_repos; i++ ))
      do

        repo=$( echo ${all_repos[0]} | cut -f $i -d " " )
        echo "$repo"

      done
    done | sort > $org.txt
      grand_total_repos=$(wc -l $org.txt | sed -nE 's/ +([0-9]+) .+/\1/p')
      echo "Total # of repositories in "\'$org\'": $grand_total_repos"
      echo "List saved to $org.txt"
  fi      #end last_repo_page == ""
}

#### MAIN

dependency_test

token_test

if [[ $# -eq 0 ]] ; then
  echo "Error: no organization name entered" 1>&2
  echo
  usage
  exit 1
fi

while [ "$1" != "" ]; do
  case $1 in
    -h | --help )         usage
                          exit ;;
    -* )                  echo "Error: invalid argument: '$1'" 1>&2
                          echo
                          usage
                          exit 1;;
    * )                   org="$1"
                          get_repos
  esac
  shift
done

exit 0

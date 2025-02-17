#!/bin/bash

# The first argument passed to the script is assigned to the variable ENTERPRISE
ENTERPRISE="$1"

# This is a GraphQL query that fetches the first 50 organizations of an enterprise
# The query takes two variables: slug (the enterprise's slug) and endCursor (for pagination)
QUERY='
query($slug:String!, $endCursor:String) {
  enterprise(slug:$slug){
    organizations(first:50, after:$endCursor){
      pageInfo{
        endCursor
        hasNextPage
      }
      nodes {
        login
      }
    }
  }
}'

# This loop iterates over each organization in the enterprise
# The 'gh api graphql' command is used to execute the GraphQL query
# The '-f' option is used to pass the query string
# The '-F' option is used to pass the enterprise's slug
# The '--jq' option is used to parse the JSON response and extract the login of each organization
for organization in $(gh api graphql -f query="${QUERY}" -F slug="${ENTERPRISE}" --jq '.data.enterprise.organizations.nodes[].login'); do
    # This line prints a message to the console
    echo "Installations for $organization"
    # This line fetches the installations for the current organization
    # The 'gh api' command is used to make a request to the GitHub API
    gh api "/orgs/$organization/installations"
done
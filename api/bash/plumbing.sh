#!/bin/bash

# building block, not intended for use by end-user
# $1 = endpoint, e.g. users/defunkt
# any remaining args = curl options
callAPI()
{
  local AUTH="Authorization: token $GH_TOKEN"
  local DOMAIN='https://api.github.com/'
  local REQUEST_URL="$DOMAIN$1"
  shift

  curl -i -H "$AUTH" "$@" "$REQUEST_URL"
}

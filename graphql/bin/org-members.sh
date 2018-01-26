#!/bin/bash

ORGANIZATION=$1
TOKEN=${GITHUB_TOKEN}

QUERY="{ \"query\": \"query { organization(login:\\\"$ORGANIZATION\\\") { members(first:100) { totalCount nodes { id, login, name, email } } } }\"}"

curl -H "Authorization: bearer ${TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  --data "$QUERY"  \
  https://api.github.com/graphql

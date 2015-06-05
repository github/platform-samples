#!/usr/bin/env bash

echo $'Have the Octocat say hello...\n'

curl -H "Authorization: token $GH_TOKEN" https://api.github.com/octocat -G --data-urlencode "s=Hello, API user."

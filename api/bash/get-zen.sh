#!/bin/bash

echo $'Retrieving a zen saying...\n'

curl -H "Authorization: token $GH_TOKEN" https://api.github.com/zen

echo $'\n'
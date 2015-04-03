#!/usr/bin/env bash

echo $'Search for repositories with the word asteroids, written in Java, sorted by stars...\n'

curl -H "Authorization: token $GH_TOKEN" https://api.github.com/search/repositories\?q\=asteroids+language:java\&sort\=stars\&order\=desc

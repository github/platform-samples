#!/usr/bin/env bash

zero_commit="0000000000000000000000000000000000000000"

# This example allows force pushes for branches named scratch/* and test/*
force_push_prefix="
scratch
test
"

is_force_push() {
  # If this is a new branch there's no history to overwrite
  if [[ ${oldrev} == ${zero_commit} ]]; then
    return 1
  fi

  if git merge-base --is-ancestor ${oldrev} ${newrev}; then
    return 1
  else
    return 0
  fi
}

while read -r oldrev newrev refname; do
  if is_force_push; then
    force_push_permitted=false
    for push_prefix in ${force_push_prefix}; do
      if [[ ${refname} == "refs/heads/${push_prefix}/"* ]]; then
        force_push_permitted=true
        break
      fi
    done
    if [[ ${force_push_permitted} == true ]]; then
      continue
    else
      echo "force push detected in restricted branch ${refname}"
      exit 1
    fi
  fi
done

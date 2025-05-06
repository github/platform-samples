#!/usr/bin/env bash

#
# Pre-receive hook that will block any pushes / repository modifications
# not performed by a user in the list (foo, bar, foobar)
#
# More details on pre-receive hooks and how to apply them can be found on
# https://help.github.com/enterprise/admin/guides/developer-workflow/managing-pre-receive-hooks-on-the-github-enterprise-appliance/
#

case $GITHUB_USER_LOGIN in
  foo|bar|foobar) echo "User $GITHUB_USER_LOGIN is allowed to push";;
  *) echo "User $GITHUB_USER_LOGIN is not in the list of authorized pushers"
     exit 1;;
esac

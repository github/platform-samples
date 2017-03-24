#!/usr/bin/env bash

#
# Pre-receive hook that will reject all merge attempts
# of a PR attempted by the author
#
# More details on pre-receive hooks and how to apply them can be found on
# https://help.github.com/enterprise/admin/guides/developer-workflow/managing-pre-receive-hooks-on-the-github-enterprise-appliance/
#

if [[ "$GITHUB_VIA" = *"merge"* ]] && [[ "$GITHUB_PULL_REQUEST_AUTHOR_LOGIN" = "$GITHUB_USER_LOGIN" ]]; then
    echo "Blocking merging of your own pull request."
    exit 1
fi

exit 0

#!/usr/bin/env bash

#
# Pre-receive hook that will reject all pushes
# Useful for locking a repository
#
# More details on pre-receive hooks and how to apply them can be found on
# https://help.github.com/enterprise/admin/guides/developer-workflow/managing-pre-receive-hooks-on-the-github-enterprise-appliance/
#

echo "You are attempting to push to the ${GITHUB_REPO_NAME} repository which has been made read-only"
echo "Access denied, push blocked. Please contact the repository administrator."

exit 1

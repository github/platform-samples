#!/usr/bin/env bash

#
# Pre-receive hook that will reject all pushes
# Useful for locking a repository
#
# More details on pre-receive hooks and how to apply them can be found on
# https://help.github.com/enterprise/admin/guides/developer-workflow/managing-pre-receive-hooks-on-the-github-enterprise-appliance/
#

echo "error: rejecting all pushes"
exit 1

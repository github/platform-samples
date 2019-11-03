#!/bin/bash
#
# Reject pushes that contain commits with messages that do not adhere
# to the defined regex.

# This can be a useful pre-receive hook [1] if you want to ensure every
# commit is associated with a ticket ID.
#
# As an example this hook ensures that the commit message contains a
# JIRA issue formatted as [JIRA-<issue number>].
#
# [1] https://help.github.com/en/enterprise/user/articles/working-with-pre-receive-hooks
#

set -e

zero_commit='0000000000000000000000000000000000000000'
msg_regex='[JIRA\-[0-9]+\]'

while read -r oldrev newrev refname; do

	# Branch or tag got deleted, ignore the push
    [ "$newrev" = "$zero_commit" ] && continue

    # Calculate range for new branch/updated branch
    [ "$oldrev" = "$zero_commit" ] && range="$newrev" || range="$oldrev..$newrev"

	for commit in $(git rev-list "$range" --not --all); do
		if ! git log --max-count=1 --format=%B $commit | grep -iqE "$msg_regex"; then
			echo "ERROR:"
			echo "ERROR: Your push was rejected because the commit"
			echo "ERROR: $commit in ${refname#refs/heads/}"
			echo "ERROR: is missing the JIRA Issue 'JIRA-123'."
			echo "ERROR:"
			echo "ERROR: Please fix the commit message and push again."
			echo "ERROR: https://help.github.com/en/articles/changing-a-commit-message"
			echo "ERROR"
			exit 1
		fi
	done

done

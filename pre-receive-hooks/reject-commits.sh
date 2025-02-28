#!/bin/bash
#
# Reject certain commits from being pushed to the repository
#
# This can be a useful pre-receive hook [1] if you rewrote the history
# of a repository and you want to ensure nobody pushes the old commits
# again.
#
# Usage: Add the commits you want to reject in the
#        "<list commit hashes here>" below.
#
# [1] https://help.github.com/en/enterprise/user/articles/working-with-pre-receive-hooks
#
set -e

zero_commit="0000000000000000000000000000000000000000"
rejected_commits=$(mktemp /tmp/rejected-commits.XXXXXX)
trap "rm -f $rejected_commits" EXIT
cat <<EOF > $rejected_commits
<list commit hashes here>
EOF

while read -r oldrev newrev refname; do

    # Branch or tag got deleted, ignore the push
    [ "$newrev" = "$zero_commit" ] && continue

    # Calculate range for new branch/updated branch
    [ "$oldrev" = "$zero_commit" ] && range="$newrev" || range="$oldrev..$newrev"

	# Iterate over all new hashes and try to match "rejected hashes"
	# Return "success" if there are no matches
	match=$(git rev-list "$range" --not --all \
		    | fgrep --max-count=1 --file=$rejected_commits \
	) || continue

	echo "ERROR:"
	echo "ERROR: Your push was rejected because it contained the commit"
	echo "ERROR: '$match' in '${refname#refs/heads/}'."
	echo "ERROR:"
	echo "ERROR: Please contact your GitHub Enterprise administrator."
	echo "ERROR"
	exit 1
done

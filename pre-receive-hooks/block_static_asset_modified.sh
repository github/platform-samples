#!/bin/bash

# this script will exit with non-0 when a static content file is modified
#   new static file objects are fine, as well as deleting files

# grab the command line args -- read from standard input
while read oldrev newrev refname; do

	# do a git difference between the master branch and the new one going to be added
	#  if a file is modified, assert it's not a static file (image or font)
	count=0
	while read -r line; do
		if [[ $line == M* ]] ; then # the line starts with M, meaning file modified

			# extract the filename, the 3rd character on
			filename=${line:2}

			# test regex for image / font file extensions -- use bash since it has regex built in
			if [[ $filename =~ (\.png)|(\.jpg)|(\.jpeg)|(\.gif)|(\.tiff)|(\.otf)|(\.eot)|(\.ttf)|(\.svg)|(\.woff) ]] ; then
				echo "error" $filename "was modified, and that file represents a static file!"
				((count++))
			fi
		fi
	done <<< `git diff --name-status master...$newrev`
	if [[ $count != 0 ]]; then
		echo "You changed "$count" static file(s)."
		echo "Create new files instead of changing them. (Due to cache settings.)"
		echo "View all files changed using this:"
		echo "git diff --name-status master..."$newrev
		exit 1
	fi
done
# good status, exit normally
exit 0

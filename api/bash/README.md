This directory contains small scripts that demonstrate some basic uses of the GitHub API.

Below are brief explanations of each script's functionality, along with instructions on how to use them.

## pretty-print.sh

### What is it?
`pretty-print.sh` displays formatted, colorized summaries of GitHub users and repositories. Quickly grab stats, get a sense of project activiy, and display clone URLs, all without leaving the command line.

### Usage
*Note: `pretty-print.sh` accepts a full GitHub username or repo URL as valid input for all commands. Also, remember to make it executable: `chmod +x pretty-print.sh`.*

Display summary of a user:
`./pretty-print.sh -u <username>`

Display a summary of a repository:
`./pretty-print.sh -r <username/repositoryname>`

Display list of forks for a GitHub repository:
`./pretty-print.sh -f <username/repositoryname>`

### Dependencies
This script uses the [jq](http://stedolan.github.io/jq/) JSON processor. Mac users can easily install it with [Homebrew](http://brew.sh): ` brew install jq `

## API Documentation
The full documentation for the GitHub API is [available here](http://developer.github.com).

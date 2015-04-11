This directory contains small scripts that demonstrate some basic uses of the GitHub API.

## Details
Below are brief explanations of each script's functionality, along with instructions on how to use them.

### pretty-print

#### What is it?
`pretty-print` displays formatted, colorized summaries of GitHub users and repositories. Quickly grab stats, get a sense of project activiy, and display clone URLs, all without leaving the command line.

#### Usage
*Note: `pretty-print` accepts a full GitHub username or repo URL as valid input for all commands.*

Display help text: 
`./pretty-print -h`

```
Usage: ./pretty-print [options] <argv>...

Options:
 -f | --forks <user/repository>   Display list of forks for a  repository
 -r | --repo  <user/repository>   Display a summary of a repository
 -u | --user  <username>          Display summary of a user
 -h | --help                      Help
 ```

#### Dependencies
`pretty-print` uses the [jq](http://stedolan.github.io/jq/) JSON processor. Mac users can easily install it with [Homebrew](http://brew.sh): ` brew install jq `

## API Documentation
The full documentation for the GitHub API is [available here](http://developer.github.com).

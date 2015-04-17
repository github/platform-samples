This directory contains small scripts that demonstrate some basic uses of the GitHub API.

## Getting Started
Many of these bash scripts require a GitHub Token to authenticate your usage of certain API features. You may [generate a new API token Here](https://github.com/settings/tokens/new). 

Once you have a valid token, you may temporarily add it as an environmental variable by running the following in your terminal window:

```
export GH_TOKEN='YOUR_GITHUB_TOKEN_GOES_HERE'
```

**Remember:** Your GitHub Token is like a password. *Never commit your token to a repository*. 

Below are brief explanations of each script's functionality, along with instructions on how to use them.

### set-status 

#### What is it?
`set-status` will [create a status for a given Ref](https://developer.github.com/v3/repos/statuses/#create-a-status) in a repository.

#### Usage
*Note: you will need push access to any repository you wish to use with `set-status`.*

```
./set-status owner/repository SHA '{"state": "success", "target_url": "https://example.com/build/status", "description": "The build succeeded!", "context": "continuous-integration/jenkins"}'
```
Where `SHA` is the full 40 character commit identifier.

### get-status

#### What is it?
`get-status` will [retrieve status for a particular Ref](https://developer.github.com/v3/repos/statuses/#get-the-combined-status-for-a-specific-ref) in a repository.

#### Usage
```
./get-status owner/repository ref
```
Where `ref` is either a SHA, branch name, or tag name.

### pretty-print

#### What is it?
`pretty-print` displays formatted, colorized summaries of GitHub users and repositories. Quickly grab stats, get a sense of project activiy, and display clone URLs, all without leaving the command line.

#### Dependencies
`pretty-print` uses the [jq](http://stedolan.github.io/jq/) JSON processor. Mac users can easily install it with [Homebrew](http://brew.sh): ` brew install jq `

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


## API Documentation
The full documentation for the GitHub API is [available here](http://developer.github.com).

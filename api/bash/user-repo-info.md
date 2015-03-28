## What is it?
`ghinfo` displays summaries of GitHub users and repositories. Quickly grab stats, get a sense of project activiy, and display clone URLs, all without leaving the command line.

## Usage
* To display a summary of a GitHub user:

  ``` ./ghinfo -u <username> ```

* To display a summary of a GitHub repository:

  ``` ./ghinfo -r <username/repositoryname> ```

* To display a list of forks for a GitHub repository:

  ``` ./ghinfo -f <username/repositoryname> ```

For all commands, `ghinfo` can also accept a full GitHub user or repo URL as valid input.

**NOTE:** `ghinfo` must be executable: ```chmod 755 ghinfo```

## Dependencies
`ghinfo` uses the [`jq` JSON processor](http://stedolan.github.io/jq/) and `curl`.

See the [detailed installation instructions for `jq`](http://stedolan.github.io/jq/download/).

Mac users can easily install `jq` with [Homebrew](http://brew.sh):

``` brew install jq ```
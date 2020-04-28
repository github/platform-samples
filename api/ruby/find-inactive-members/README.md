# Find Inactive Organization Members

```
find_inactive_members.rb - Find and output inactive members in an organization
    -c, --check                      Check connectivity and scope
    -d, --date MANDATORY             Date from which to start looking for activity (in a format parseable by the Ruby Date class: https://ruby-doc.org/stdlib/libdoc/date/rdoc/Date.html)
    -e, --email                      Fetch the user email (can make the script take longer)
    -o, --organization MANDATORY     Organization to scan for inactive users
    -v, --verbose                    More output to STDERR
    -h, --help                       Display this help
```

This utility finds users inactive since the given date and writes those users to the file `inactive_users.csv`.

## Installation

### Clone this repository

```shell
git clone https://github.com/github/platform-samples.git
cd platform-samples/api/ruby/find-inactive-members
```

### Install dependencies

```shell
gem install octokit
```

### Configure Octokit

The `OCTOKIT_ACCESS_TOKEN` is required in order to see activities on private repositories. Also note that GitHub.com has an rate limit of 60 unauthenticated requests per hour, which this tool can easily exceed. Access tokens can be generated at https://github.com/settings/tokens. The `OCTOKIT_API_ENDPOINT` isn't required if connecting to GitHub.com, but is required if connecting to a GitHub Enterprise instance.

```shell
export OCTOKIT_ACCESS_TOKEN=00000000000000000000000     # Required if looking for activity in private repositories.
export OCTOKIT_API_ENDPOINT="https://<your_github_enterprise_instance>/api/v3" # Not required if connecting to GitHub.com.
```

## Usage

```
ruby find_inactive_members.rb [-cehv] -o ORGANIZATION -d DATE
```

## Examples
```
ruby find_inactive_members.rb -o YoyodynePropulsionSystems -d "Feb 10 2020"
```

## How Inactivity is Defined

Members are defined as inactive if they **have not performed** any of the following actions in any repository in the specified **ORGANIZATION** since the specified **DATE**: 

- Merged or pushed commits into the default branch
- Opened an Issue or Pull Request
- Commented on an Issue or Pull Request

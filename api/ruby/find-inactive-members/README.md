# Find Inactive Organization Members

```
find_inactive_members.rb - Find and output inactive members in an organization
    -c, --check                      Check connectivity and scope
    -d, --date MANDATORY             Date from which to start looking for activity
    -e, --email                      Fetch the user email (can make the script take longer
    -o, --organization MANDATORY     Organization to scan for inactive users
    -v, --verbose                    More output to STDERR
    -b, --branches                   Iterate through all branches instead of only checking the default branch
    -h, --help                       Display this help
```

This utility finds users inactive since a configured date, writes those users to a file `inactive_users.csv`.

## Installation

### Clone this repository

```shell
git clone https://github.com/github/platform-samples.git
cd api/ruby/find-inactive-members
```

### Install dependencies

```shell
gem install octokit
```

### Configure Octokit

The `OCTOKIT_ACCESS_TOKEN` is required in order to see activities on private repositories. However the `OCTOKIT_API_ENDPOINT` isn't required if connecting to GitHub.com, but is required if connecting to a GitHub Enterprise Server instance.

```shell
export OCTOKIT_ACCESS_TOKEN=00000000000000000000000     # Required if looking for activity in private repositories.
export OCTOKIT_API_ENDPOINT="https://<your_github_enterprise_instance>/api/v3" # Not required if connecting to GitHub.com.
```

## Usage

1. Generate new GitHub token https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line with scopes `repo` and `admin:org`
2. Clone this repository `git clone git@github.com:github/platform-samples.git`
3. Navigate to the right directory and set the environment: `export OCTOKIT_ACCESS_TOKEN=[paste token here]` (`OCTOKIT_API_ENDPOINT` is only necessary for GitHub Enterprise Server)
4. Run the report script: `ruby find_inactive_members.rb [-bcehv] -o ORGANIZATION -d DATE`



## How Inactivity is Defined

Members are defined as inactive if they haven't, since the specified **DATE**,  in any repository in the specified **ORGANIZATION**:

* Have not merged or pushed commits into the default branch
* Have not opened an Issue or Pull Request
* Have not commented on an Issue or Pull Request

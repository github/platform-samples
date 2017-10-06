# Find Inactive Organization Members
> a utility to find, and optionally remove, inactive organization members

This utility finds users inactive since a configured date, writes those users to a file `inactive_users.csv`, and optionally removes them from the organization

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

```shell
export OCTOKIT_API_ENDPOINT="https://github.example.com/api/v3" # Default: "https://api.github.com"
export OCTOKIT_ACCESS_TOKEN=00000000000000000000000
```

## Usage

```shell
ruby member_audit.rb orgName YYYY-MM-DD
```

or, to automatically remove inactive members

```shell
ruby member_audit.rb orgName YYYY-MM-DD purge
```

## How Inactivity is Defined

Members are defined as inactive if:

* They have not committed to a repository in the org since the `SINCE_DATE`
* They have not opened an issue or PR that has had activity since the `SINCE_DATE`
* They have not commented on an issue or PR since the `SINCE_DATE`

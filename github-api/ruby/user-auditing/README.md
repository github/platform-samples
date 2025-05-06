# Suspended User Audit

Lists total number of active, suspended, and recently suspended users. Gives the option to unsuspend all recently suspended users. This is mostly useful when a configuration change may have caused a large number of users to become suspended.

## Installation


### Clone this repository

```shell
git clone git@github.com:github/platform-samples.git
cd api/ruby/user-auditing
```


### Install dependencies

```shell
gem install octokit
```


## Usage

### Configure Octokit

```shell
export OCTOKIT_API_ENDPOINT="https://github.example.com/api/v3" # Default: "https://api.github.com"
export OCTOKIT_ACCESS_TOKEN=00000000000000000000000
```

### Execute

```shell
ruby suspended_user_audit.rb
```

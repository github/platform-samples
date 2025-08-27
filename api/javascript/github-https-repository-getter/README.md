# github-repo-getter

* Download Enterprise Repository from GitHub through the CLI using HTTPS;

* Command Line utility that automatically downloads a Repository @branch from your enterprise organization. 

* This package uses HTTPS instead of GIT to retrieve repositories. This allows you to retrieve projects securely from within restricted networks by whitelisting a machine IP egress at the network firewall level after SSHing into that machine.

## USAGE

**Installation**

* npm i -g github-repo-getter

**Prompts**

* <user>$: `github-repo-getter`

* Enter GitHub username.

* Enter Organization name.

* Enter Repository name.

* Enter Branch name.

* Enter personal access token

> You should now have that repository in your local filesystem.

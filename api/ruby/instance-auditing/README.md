# Instance auditor

This script creates an spreadsheet file that will allow you to audit the access of each team and user with all of the organizations across your GitHub Enterprise instance.

## Getting started

The user who is going to run the script must be on the "Owners" team of every organization you wish to audit. You can promote all users with Site Admin access to owners of every organization by running [`ghe-org-admin-promote`](https://help.github.com/enterprise/admin/articles/command-line-utilities/#ghe-org-admin-promote).

You will also need to [generate a Personal Access Token](https://help.github.com/enterprise/user/articles/creating-an-access-token-for-command-line-use/) for that user with the `admin:org` permission.

## Output

This utility will create a file in the same directory called `audit.xlsx` containing the audit data. 

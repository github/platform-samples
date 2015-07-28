# Instance auditor

This script creates an spreadsheet file that will allow you to audit the access of each team and user with all of the Organizations across your GitHub Enterprise instance.

## Getting started

Before running the script, the user who is going to run the script must be on the "Owners" team of every Organization you wish the audit. You can promote all users with Site Admin access to Owners of each Organization by running [`ghe-org-admin-promote`](https://help.github.com/enterprise/admin/articles/command-line-utilities/#ghe-org-admin-promote).

You will need to acquire a Personal Access Token for that user with the `admin:org` permission as well to be used with this utility.

## Output

The utility will create a file in the same directory called "audit.xlsx" containing the audit data. 

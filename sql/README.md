# SQL Queries for GitHub Enterprise Server

:warning: While these are all read-only queries and do not write to the database, run these directly against your GitHub Enterprise Server database at your own risk.  A safer method to run these is outlined [here](USAGE.md).

Each query has a comment at the top of the file elaborating what it does, etc.

## Audit queries

The `audit` folder has queries that are all around auditing credentials, webhooks, apps, etc.

- `admin-tokens.sql` - A report of all tokens with the `site_admin` scope and when they were last used.
- `authorizations.sql` - A report of all personal access tokens and when they were last used.  Same as above, but without the `site_admin` scope limitation.  This is a big report.
- `deploy-keys.sql` - A report of all deploy keys, when it was last used, who set it up and when, how long the key is, and what repository it's tied to.
- `github-apps.sql` - A report of all GitHub apps, who owns them, the scope it's installed at, if it's public or not, and the URL it's sending data to.
- `hooks-repos.sql` - A report of all repository webhooks used in the past week, who owns it, and where the webhook goes.  This is limited to a week based on the length of time these are kept in the `hookshot_delivery_logs` table.
- `hooks-users.sql` - Same report as above, but for user-owned webhooks.
- `oauth-apps.sql` - A report of all OAuth apps, who owns it, where it goes, and when it was last used.
- `repos-audit.sql` - A report of all repositories including the commit count, PR count, Disk size, last push, and more. 
- `user-emails.sql` - A report of all emails that don't match a list of approved domains you define in the `WHERE` clause.  This query should be deprecated by [this issue](https://github.com/github/roadmap/issues/204).
- `user-ssh-keys.sql` - A report of all user SSH keys, when it was last used, when it was set up, and how long the key is.

## Metrics queries

The `metrics` folder has queries that are all around usage of various features in GitHub Enterprise Server.

- `actions-summary.sql` - A monthly summary of runtime hours, seconds waiting in queue before dispatch, and job count for GitHub Actions usage.
- `commit-count.sql` - This pulls a "high score" report of all users, all commits, from all time.
- `commit-summary.sql` - A month-by-month summary of commits pushed to GitHub Enterprise Server (using the commit date).
- `count-tabs.sql` - A report of the custom tabs users put in their repositories.
- `issue-report.sql` - A report of active issues within the past X days.
- `linguist-report.sql` - This returns the "size" of each language in each repository and when the repo was last updated.  This can be a very large report.
- `linguist-stats.sql` - This returns the count of repositories containing each language and a sum "size" of code in that language for all repos pushed to in the past year.  The time limit is adjustable.
- `most-recent-active-repos.sql` - A list of repositories, when they were last updated, who owns them, and the disk space associated with each.
- `pr-report.sql` - This pulls a report of pull requests including the repo name, user name, files included, times it was created/updated/merged, and comments.  It can filter by organization or return all PRs in GHES.
- `prereceive-hooks.sql` - A list of pre-receive hooks that are enabled by each repository and who owns the repo.
- `public-repo-owners.sql` - A list of all users or orgs who own repositories marked as "public", a count of public repos, and the user or org email address.
- `reaction-stats.sql` - A count of the reactions used in GHES for trivia.
- `staff-notes.sql` - Returns a list of organizations or users with `staff_notes`.
- `user-report.sql` - Returns username, id, created/suspended date, issues created for all time and in the past 30 days, number of repos owned, and how many pull requests they've opened.

## Security queries

The `security` folder has queries that are all around dependency alerts and any other security features.

- `active-repo-report.sql` - A list of all detected HIGH and CRITICAL vulnerabilities from repos pushed to in the past 90 days.  It also returns who owns it and further details on the exact vulnerability.  The threshold of time and severity to return is adjustable.
- `vuln-critical-count.sql` - A count of repositories affected by each CRITICAL vulnerability.
- `vuln-report.sql` - A report of all detected vulnerabilities in every single repo in GHES, who owns it, when it was last pushed to, the platform of the vulnerability, and the GHSA/MITRE/WhiteSource info on it.  This can be a very large report.

# SQL Queries for GitHub Enterprise Server

:warning: Run these directly against your GitHub Enterprise Server database at your own risk.  A safer method to run these is outlined [here](USAGE.md).

## Audit queries

The `audit` folder has queries that are all around auditing credentials, webhooks, apps, etc.

- `admin-tokens.sql` - A report of all tokens with the `site_admin` scope and when they were last used.
- `authorizations.sql` - A report of all personal access tokens and when they were last used.  Same as above, but without the `site_admin` scope limitation.  This is a big report.
- `deploy-keys.sql` - A report of all deploy keys, when it was last used, who set it up and when, how long the key is, and what repository it's tied to.
- `github-apps.sql` - A report of all GitHub apps, who owns them, the scope it's installed at, if it's public or not, and the URL it's sending data to.
- `hooks-repos.sql` - A report of all repository webhooks used in the past week, who owns it, and where the webhook goes.  This is limited to a week based on the length of time these are kept in the `hookshot_delivery_logs` table.
- `hooks-users.sql` - Same report as above, but for user-owned webhooks.
- `oauth-apps.sql` - A report of all OAuth apps, who owns it, where it goes, and when it was last used.
- `user-emails.sql` - A report of all emails that don't match a list of approved domains you define in the `WHERE` clause.  This query should be deprecated by [this issue](https://github.com/github/roadmap/issues/204).
- `user-ssh-keys.sql` - A report of all user SSH keys, when it was last used, when it was set up, and how long the key is.

## Security queries

The `security` folder has queries that are all around dependency alerts and any other security features.

## Usage queries

The `usage` folder has queries that are all around usage of various features in GitHub Enterprise Server.

#!/bin/bash
#
# Hook that rejects pushes that contain commits with invalid email addresses
#
# Attention: The script might timeout if many new refs are pushed
#

# DOMAIN=[Your company's domain name]
# COMPANY_NAME=[Your company name]
# CONTACT_EMAIL=help@company.com
# SLACK=#help-git
# HELP_URL=https://pages.github.company.com/org/repo
# BOT_PATTERN=^svc-
# OSS_ORGS=^(company-forks|opensource)/

if [[ -z "$DOMAIN" ]] \
    && [[ -z "$COMPANY_NAME" ]] \
    && [[ -z "$CONTACT_EMAIL" ]] \
    && [[ -z "$SLACK" ]] \
    && [[ -z "$HELP_URL" ]]
then
    echo "WARNING: the GitHub Enterprise site administrator must configure the reject-external-emails.sh script!"
    exit 0
fi

# Customized message to help users understand and/or resolve the `git config --global user.email` issue
help_message() {
    echo "WARNING: See $HELP_URL for instructions."
    echo "WARNING:"
    echo "WARNING: Contact $CONTACT_EMAIL or $SLACK on Slack for assistance!"
    echo "WARNING:"
}

# Ignore pushes from service/bot accounts
[[ -n "$BOT_PATTERN" ]] && [[ "$GITHUB_USER_LOGIN" =~ $BOT_PATTERN ]] && exit 0

# Ignore pushes to organizations that contain lots of non-DOMAIN emails.
[[ -n "$OSS_ORGS" ]] && [[ "$GITHUB_REPO_NAME" =~ $OSS_ORGS ]] && exit 0

ZERO_COMMIT="0000000000000000000000000000000000000000"
while read -r OLDREV NEWREV REFNAME; do

    if [[ "$NEWREV" = "$ZERO_COMMIT" ]]
    then
        # Branch or tag got deleted
        continue
    elif [[ "$OLDREV" = "$ZERO_COMMIT" ]]
    then
        # New branch or tag
        SPAN=$(git rev-list "$NEWREV" --not --all)
    else
        SPAN=$(git rev-list "$OLDREV".."$NEWREV" --not --all)
    fi

    for COMMIT in $SPAN
    do
        AUTHOR_EMAIL=$(git log --format=%ae -n 1 "$COMMIT")

        if ! [[ "$AUTHOR_EMAIL" =~ ^[A-Za-z0-9._-]+@"$DOMAIN"$ ]]
        then
            echo "WARNING:"
            echo "WARNING: At least one commit on '${REFNAME#refs/heads/}' does not have an '$DOMAIN' email address."
            echo "WARNING:         commit: $COMMIT"
            echo "WARNING:   author email: $AUTHOR_EMAIL"
            echo "WARNING:"
            help_message
            exit 1
        fi
    done

done

# org-invite

Use this script send invites in bulk to join a team (new or existing) under an organization on GitHub.

![Screenshot](screenshot.png?raw=true "Script in action")

# Instructions

Checkout this repo and make sure you're using Node v10 or more recent. 
You can supply default values in an `.env` file (gitignored for security reasons):

```
GH_PAT=YOUR_PAT_GOES_HERE
GH_USER=octocat
GH_ORG=github
```
You will need to be an owner of the organization and the PAT will need read/write access to the Org permission scope.
To run the first time:
```
npm install # do this only once
node cli.js
```

Follow the interactive prompt to supply the team you want to invite members to, and the comma-separated list of email addresses (or existing usernames) you want to invite.


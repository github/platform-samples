GitHub Search API demo
=================

This project employs several authentication strategies to avoid rate limiting while using the GitHub Search API:
1. Using each user's OAuth access token, if available -- this will allow you a maximum of [30 requests per-user / per-minute](https://developer.github.com/v3/search/#rate-limit)
2. Falling back to a server-to-server token, associated with a given installation of your GitHub App -- this will allow you a maximum of [30 requests per-organization / per-minute](https://developer.github.com/v3/search/#rate-limit)
3. Falling back again to simplified functionality, such as validating a given GitHub username, via GET /users/:username -- this will allow you a minimum of [5000 requests per-organization / per-hour](https://developer.github.com/apps/building-github-apps/understanding-rate-limits-for-github-apps/)

Step 1a: Prereqs via [Glitch](https://glitch.com/~github-search-api)
-----------

* Remix this app :)
  
Step 1b: Prereqs locally
-----------
* Install `node` from [the website](https://nodejs.org/en/) or [Homebrew](https://brew.sh/)
* `git clone` the project
* Navigate to the project directory and install dependencies using `npm i`

Step 2: App creation and variable-setting
-----------
* Create a new [GitHub App](https://developer.github.com/apps/building-github-apps/creating-a-github-app/).
  * Homepage URL = `<Your Glitch App URL>`
  * User authorization callback URL = `<Your Glitch App URL>/authorized`
  * Webhook URL (unused) = `<Your Glitch App URL>/hooks`
  * Download your private key at the bottom of the app settings page.
* Make a new file in Glitch called `.data/pem` and paste the contents of the private key.
* Set the following variables in your Glitch `.env` file:
  * `GH_CLIENT_ID` Client ID on app settings page
  * `GH_CLIENT_SECRET` Client secret on app settings page
  * `GH_APP_ID` App ID on app settings page
  * `INSTALLATION_ID` Installation ID, which you can retrieve from [here](https://developer.github.com/v3/apps/installations/#installations)
  
Step 3a: Running via Glitch
-----------
* Navigate to your URL for live-reloaded goodness

Step 3b: Running locally
-----------
* `npm start`
  
FYI
-----------
* This app is single-user (for now). It stores the OAuth token in a file found at `.data/oauth`.

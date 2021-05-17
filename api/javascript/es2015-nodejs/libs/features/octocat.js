/*
# Zen of GitHub

## Setup

```javascript
const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;
const octocat = require('../libs/features/octocat');


let githubCli = new GitHubClient({
  baseUri: "http://github.at.home/api/v3",
  token: process.env.TOKEN_GHITHUB_ENTERPRISE
}, octocat); //<-- add octocat feature
```
 */
const fetch = require('node-fetch');

/*
## octocat

- return: `Promise`

### Description

`octocat` gets octocat mindset

 */
function octocat() {
  let _response = {};
  return fetch(this.baseUri + `/octocat`, {
    method: 'GET',
    headers: this.headers
  })
  .then(response => {
    if (response.ok) {
      return response.text()
    } else {
      throw new HttpException({
        message: "HttpException",
        status:response.status,
        statusText:response.statusText,
        url: response.url
      });
    }
  })
}

module.exports = {
  octocat: octocat
};

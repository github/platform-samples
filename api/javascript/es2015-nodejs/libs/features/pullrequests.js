/*
# Pull Requests features

## Setup

```javascript
const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;
const pullrequests = require('../libs/features/pullrequests');


let githubCli = new GitHubClient({
  baseUri: "http://github.at.home/api/v3",
  token: process.env.TOKEN_GHITHUB_ENTERPRISE
}, pullrequests); //<-- add pullrequests features
```
*/

/*
## createPullRequest

- parameter: `title, body, head, base, owner, repository`
- return: `Promise`

### Description

`createPullRequest` creates a PR

*/
function createPullRequest({title, body, head, base, owner, repository}) {
  return this.postData({path:`/repos/${owner}/${repository}/pulls`, data:{
    title, body, head, base
  }}).then(response => {
    return response.data;
  });
}

module.exports = {
  createPullRequest: createPullRequest
};

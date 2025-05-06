/*
# Commits features

## Setup

```javascript
const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;
const commits = require('../libs/features/commits');


let githubCli = new GitHubClient({
  baseUri: "http://github.at.home/api/v3",
  token: process.env.TOKEN_GHITHUB_ENTERPRISE
}, commits); //<-- add commits features
```
*/

/*
## fetchCommitBySHA

- parameter: `sha, owner, repository`
- return: `Promise`

### Description

`fetchCommitBySHA` gets a commit by its sha

*/
function fetchCommitBySHA({sha, owner, repository}){
  return this.getData({path:`/repos/${owner}/${repository}/git/commits/${sha}`})
    .then(response => {
      return response.data;
    });
}

module.exports = {
  fetchCommitBySHA: fetchCommitBySHA
};

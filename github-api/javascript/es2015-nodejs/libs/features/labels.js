/*
# Labels features

## Setup

```javascript
const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;
const labels = require('../libs/features/labels');


let githubCli = new GitHubClient({
  baseUri: "http://github.at.home/api/v3",
  token: process.env.TOKEN_GHITHUB_ENTERPRISE
}, labels); //<-- add labels features
```
*/

/*
## createLabel

- parameter: `name, color, owner, repository`
- return: `Promise`

### Description

`createLabel` creates a label for a repository

*/
function createLabel({name, color, owner, repository}) {
  return this.postData({path:`/repos/${owner}/${repository}/labels`, data:{
    name: name,
    color: color
  }}).then(response => {
    return response.data;
  });
}

module.exports = {
  createLabel: createLabel
};

/*
# Hooks features

## Setup

```javascript
const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;
const hooks = require('../libs/features/hooks');


let githubCli = new GitHubClient({
  baseUri: "http://github.at.home/api/v3",
  token: process.env.TOKEN_GHITHUB_ENTERPRISE
}, hooks); //<-- add hooks features
```
*/

/*
## createHook

- parameter: `owner, repository, hookName, hookConfig, hookEvents, active`
- return: `Promise`

### Description

`createHook` creates a hook for a repository

*/
function createHook({owner, repository, hookName, hookConfig, hookEvents, active}) {
  return this.postData({path:`/repos/${owner}/${repository}/hooks`, data:{
    name: hookName
    , config: hookConfig
    , events: hookEvents
    , active: active
  }}).then(response => {
    return response.data;
  });
}

/*
## createOrganizationHook

- parameter: `org, hookName, hookConfig, hookEvents, active`
- return: `Promise`

### Description

`createOrganizationHook` creates a hook for an organization

 */
function createOrganizationHook({org, hookName, hookConfig, hookEvents, active}) {
  return this.postData({path:`/orgs/${org}/hooks`, data:{
    name: hookName
    , config: hookConfig
    , events: hookEvents
    , active: active
  }}).then(response => {
    return response.data;
  });
}

module.exports = {
  createHook: createHook,
  createOrganizationHook: createOrganizationHook
};

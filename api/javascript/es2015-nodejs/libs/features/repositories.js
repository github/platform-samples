/*
# Repositories features

 ## Setup

```javascript
const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;
const repositories = require('../libs/features/repositories');


let githubCli = new GitHubClient({
  baseUri: "http://github.at.home/api/v3",
  token: process.env.TOKEN_GHITHUB_ENTERPRISE
}, repositories); //<-- add repositories features
```
*/

/*
## fetchUserRepositories

- parameter: `handle`
- return: `Promise`

### Description

`fetchUserRepositories` gets the list of the repositories of a user (`handle`)

*/
function fetchUserRepositories({handle}) {
  return this.getData({path:`/users/${handle}/repos`})
    .then(response => {
      return response.data;
    });
}

/*
## fetchOrganizationRepositories

- parameter: `organization` (organization name)
- return: `Promise`

### Description

`fetchOrganizationRepositories` gets the list of the repositories of an organization

*/
function fetchOrganizationRepositories({organization}) {
  return this.getData({path:`/orgs/${organization}/repos`})
    .then(response => {
      return response.data;
    });
}

/*
## createPublicRepository

- parameters: `name, description`
- return: `Promise`

### Description

`createPublicRepository` creates a public repository for the authenticated user

*/
function createPublicRepository({name, description}) {
  return this.postData({path:`/user/repos`, data:{
    name: name,
    description: description,
    private: false,
    has_issue: true,
    has_wiki: true,
    auto_init: true
  }}).then(response => {
    return response.data;
  });
}

/*
## createPrivateRepository

- parameters: `name, description`
- return: `Promise`

### Description

`createPrivateRepository` creates a private repository for the authenticated user

*/
function createPrivateRepository({name, description}) {
  return this.postData({path:`/user/repos`, data:{
    name: name,
    description: description,
    private: true,
    has_issue: true,
    has_wiki: true,
    auto_init: true
  }}).then(response => {
    return response.data;
  });
}

/*
## createPublicOrganizationRepository

- parameters: `name, description, organization`
- return: `Promise`

### Description

`createPublicOrganizationRepository` creates a public repository for an organization

*/
function createPublicOrganizationRepository({name, description, organization}) {
  return this.postData({path:`/orgs/${organization}/repos`, data:{
    name: name,
    description: description,
    private: false,
    has_issue: true,
    has_wiki: true,
    auto_init: true
  }}).then(response => {
    return response.data;
  });
}

/*
## createPrivateOrganizationRepository

- parameters: `name, description, organization`
- return: `Promise`

### Description

`createPrivateOrganizationRepository` creates a private repository for an organization

*/
function createPrivateOrganizationRepository({name, description, organization}) {
  return this.postData({path:`/orgs/${organization}/repos`, data:{
    name: name,
    description: description,
    private: true,
    has_issue: true,
    has_wiki: true,
    auto_init: true
  }}).then(response => {
    return response.data;
  });
}


module.exports = {
  fetchUserRepositories: fetchUserRepositories,
  fetchOrganizationRepositories: fetchOrganizationRepositories,
  createPublicRepository: createPublicRepository,
  createPrivateRepository: createPrivateRepository,
  createPublicOrganizationRepository: createPublicOrganizationRepository,
  createPrivateOrganizationRepository: createPrivateOrganizationRepository
};
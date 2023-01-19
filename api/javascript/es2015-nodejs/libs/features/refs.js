/*
# Refs features

## Setup

```javascript
const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;
const refs = require('../libs/features/refs');


let githubCli = new GitHubClient({
  baseUri: "http://github.at.home/api/v3",
  token: process.env.TOKEN_GHITHUB_ENTERPRISE
}, refs); //<-- add refs features
```
*/

/*
## getReference

- parameter: `owner, repository, ref`
- return: `Promise`

### Description

`getReference` gets the ref of a repository

*/
function getReference({owner, repository, ref}){
  return this.getData({path:`/repos/${owner}/${repository}/git/refs/${ref}`})
    .then(response => {
      return response.data;
    });
}

/*
## createReference

- parameter: `ref, sha, owner, repository`
- return: `Promise`

### Description

`createReference` creates a ref

*/
function createReference({ref, sha, owner, repository}) {
  return this.postData({path:`/repos/${owner}/${repository}/git/refs`, data:{
    ref, sha
  }}).then(response => {
    return response.data;
  });
}

/*
## createBranch

- parameter: `branch, from, owner, repository`
- return: `Promise`

### Description

`createBranch` creates a branch from head ref

*/
function createBranch({branch, from, owner, repository}) {
  return this.getReference({
      owner: owner
    , repository: repository
    , ref: `heads/${from}`
  }).then(data => {
    let sha = data.object.sha
    return this.createReference({
      ref: `refs/heads/${branch}`
      , sha: sha
      , owner: owner
      , repository: repository
    })
  })
}

/*
## createBranchFromRelease

- parameter: `branch, from, owner, repository`
- return: `Promise`

### Description

`createBranchFromRelease` creates a branch from tags ref

*/
function createBranchFromRelease({branch, from, owner, repository}) {
  return this.getReference({
      owner: owner
    , repository: repository
    , ref: `tags/${from}`
  }).then(data => {
    let sha = data.object.sha
    return this.createReference({
      ref: `refs/heads/${branch}`
      , sha: sha
      , owner: owner
      , repository: repository
    })
  })
}

module.exports = {
  getReference: getReference,
  createReference: createReference,
  createBranch: createBranch,
  createBranchFromRelease: createBranchFromRelease
};

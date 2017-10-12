/*
# Issues features

## Setup

```javascript
const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;
const issues = require('../libs/features/issues');


let githubCli = new GitHubClient({
  baseUri: "http://github.at.home/api/v3",
  token: process.env.TOKEN_GHITHUB_ENTERPRISE
}, issues); //<-- add issues features
```
*/

/*
## createIssue

- parameter: `title, body, labels, milestone, assignees, owner, repository`
- return: `Promise`

### Description

`createIssue` creates an issue for a repository

*/
function createIssue({title, body, labels, milestone, assignees, owner, repository}) {
  return this.postData({path:`/repos/${owner}/${repository}/issues`, data:{
    title, body, labels, milestone, assignees, owner, repository
  }}).then(response => {
    return response.data;
  });
}

/*
## fetchIssue

- parameter: `owner, repository, number`
- return: `Promise`

### Description

`fetchIssue` gets an issue by its number

*/
function fetchIssue({owner, repository, number}) {
  return this.getData({path:`/repos/${owner}/${repository}/issues/${number}`})
    .then(response => {
      return response.data;
    });
}

/*
## fetchIssues

- parameter: `owner, repository`
- return: `Promise`

### Description

`fetchIssues` gets the list of the issues of a repository

*/
function fetchIssues({owner, repository}) {
  return this.getData({path:`/repos/${owner}/${repository}/issues`})
    .then(response => {
      return response.data;
    });
}

/*
## addIssueComment

- parameter: `owner, repository, number, body`
- return: `Promise`

### Description

`addIssueComment` adds a comment to an issue by its number

*/
function addIssueComment({owner, repository, number, body}) {
  return this.postData({path:`/repos/${owner}/${repository}/issues/${number}/comments`, data:{
    body
  }}).then(response => {
    return response.data;
  });
}

/*
## fetchIssueComments

- parameter: `owner, repository, number`
- return: `Promise`

### Description

`fetchIssueComments` gets all comments of an issue by its number

*/
function fetchIssueComments({owner, repository, number}) {
  return this.getData({path:`/repos/${owner}/${repository}/issues/${number}/comments`})
    .then(response => {
      return response.data;
    });
}

/*
## addIssueReaction

- parameter: `owner, repository, number, content`
- return: `Promise`

### Description

`addIssueReaction` adds a reaction (`+1`, `-1`, `laugh`, `confused`, `heart`, `hooray`) to the body of an issue

*/
function addIssueReaction({owner, repository, number, content}) {
  let saveAccept = this.headers["Accept"];
  this.headers["Accept"] = "application/vnd.github.squirrel-girl-preview";
  return this.postData({path:`/repos/${owner}/${repository}/issues/${number}/reactions`, data:{
    content
  }}).then(response => {
    this.headers["Accept"] = saveAccept;
    return response.data;
  });
}

/*
## addIssueCommentReaction

- parameter: `owner, repository, id, content`
- return: `Promise`

### Description

`addIssueCommentReaction` adds a reaction (`+1`, `-1`, `laugh`, `confused`, `heart`, `hooray`) to a comment of an issue

*/
function addIssueCommentReaction({owner, repository, id, content}) {
  let saveAccept = this.headers["Accept"];
  this.headers["Accept"] = "application/vnd.github.squirrel-girl-preview";
  return this.postData({path:`/repos/${owner}/${repository}/issues/comments/${id}/reactions`, data:{
    content
  }}).then(response => {
    this.headers["Accept"] = saveAccept;
    return response.data;
  });
}

module.exports = {
  createIssue: createIssue,
  fetchIssue: fetchIssue,
  fetchIssues: fetchIssues,
  addIssueComment: addIssueComment,
  fetchIssueComments: fetchIssueComments,
  addIssueReaction: addIssueReaction,
  addIssueCommentReaction: addIssueCommentReaction
};

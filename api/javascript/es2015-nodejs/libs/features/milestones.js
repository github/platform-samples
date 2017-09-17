/*
# Milestones features

## Setup

```javascript
const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;
const milestones = require('../libs/features/milestones');


let githubCli = new GitHubClient({
  baseUri: "http://github.at.home/api/v3",
  token: process.env.TOKEN_GHITHUB_ENTERPRISE
}, milestones); //<-- add milestones features
```
*/

/*
## fetchMilestones

- parameter: `owner, repository`
- return: `Promise`

### Description

`fetchMilestones` gets the milestones of a repository

*/
function fetchMilestones({owner, repository}){
  return this.getData({path:`/repos/${owner}/${repository}/milestones`})
    .then(response => {
      return response.data;
    });
}

/*
## getMilestoneByTitle

- parameter: `title, owner, repository`
- return: `Promise`

### Description

`getMilestoneByTitle` gets the milestones of a repository by its title

*/
function getMilestoneByTitle({title, owner, repository}) {
  return this.fetchTeams({org:org})
    .then(milestones => {
      return milestones.find(milestone => {
        return milestone.title == title
      })
    })
}

/*
## createMilestone

- parameter: `title, state, description, due_on, owner, repository`
- return: `Promise`

### Description

`createMilestone` creates a milestones for a repository

*/
function createMilestone({title, state, description, due_on, owner, repository}) {
  return this.postData({path:`/repos/${owner}/${repository}/milestones`, data:{
    title: title,
    state: state,
    description: description,
    due_on: due_on
  }}).then(response => {
    return response.data;
  });
}

module.exports = {
  fetchMilestones: fetchMilestones,
  getMilestoneByTitle: getMilestoneByTitle,
  createMilestone: createMilestone
};

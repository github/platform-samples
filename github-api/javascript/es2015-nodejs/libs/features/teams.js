/*
# Teams features

## Setup

```javascript
const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;
const teams = require('../libs/features/teams');


let githubCli = new GitHubClient({
  baseUri: "http://github.at.home/api/v3",
  token: process.env.TOKEN_GHITHUB_ENTERPRISE
}, teams); //<-- add teams features
```
*/

/*
## createTeam

- parameters: `org, name, description, repo_names, privacy, permission`
- return: `Promise`

### Description

`createTeam` creates a team for an organization with permissions on a list of repositories

*/
function createTeam({org, name, description, repo_names, privacy, permission}) {
  return this.postData({path:`/orgs/${org}/teams`, data:{
    name: name,
    description: description,
    repo_names: repo_names,
    privacy: privacy, // secret or closed
    permission: permission // pull, push, admin
  }}).then(response => {
    return response.data;
  });
}

/*
## fetchTeams

- parameters: `org`
- return: `Promise`

### Description

`fetchTeams` gets the list of the teams of the organization

*/
function fetchTeams({org}) {
  return this.getData({path:`/orgs/${org}/teams`})
    .then(response => {
      return response.data;
    });
}

/*
## getTeamByName

- parameters: `org, name`
- return: `Promise`

### Description

`getTeamByName` gets a team by its name

*/
function getTeamByName({org, name}) {
  return this.fetchTeams({org:org})
    .then(teams => {
      return teams.find(team => {
        return team.name == name
      })
    })
}

/*
## updateTeamRepository

- parameters: `teamId, organization, repository, permission`
- return: `Promise`

### Description

`updateTeamRepository` updates permissions of the team on a repository

*/
function updateTeamRepository({teamId, organization, repository, permission}) {
  return this.putData({path:`/teams/${teamId}/repos/${organization}/${repository}`, data:{
    permission: permission
  }}).then(response => {
    return response.data;
  });
}

/*
## addTeamMembership

- parameters: `teamId, userName, role`
- return: `Promise`

### Description

`addTeamMembership` ads role to the team

*/
function addTeamMembership({teamId, userName, role}) {
  return this.putData({path:`/teams/${teamId}/memberships/${userName}`, data:{
    role: role // member, maintener
  }}).then(response => {
    return response.data;
  });
}


module.exports = {
  createTeam: createTeam,
  fetchTeams: fetchTeams,
  getTeamByName: getTeamByName,
  updateTeamRepository: updateTeamRepository,
  addTeamMembership: addTeamMembership
};
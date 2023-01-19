/*
# Organizations features

## Setup

```javascript
const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;
const organizations = require('../libs/features/organizations');


let githubCli = new GitHubClient({
  baseUri: "http://github.at.home/api/v3",
  token: process.env.TOKEN_GHITHUB_ENTERPRISE
}, organizations); //<-- add organizations features
```
*/

/*
## createOrganization

- parameters: `login, admin, profile_name`
- return: `Promise`

```
login: The organization's username.
admin: The login of the user who will manage this organization.
profile_name:	The organization's display name.
```

### Description

`createOrganization` creates an organization

*/
function createOrganization({login, admin, profile_name}) {
  return this.postData({path:`/admin/organizations`, data:{
    login: login,
    admin: admin,
    profile_name: profile_name
  }}).then(response => {
    return response.data;
  });
}

/*
## addOrganizationMembership

- parameters: `org, userName, role`
- return: `Promise`


### Description

`addOrganizationMembership` adds a role for a user of an organization

*/
function addOrganizationMembership({org, userName, role}) {
  return this.putData({path:`/orgs/${org}/memberships/${userName}`, data:{
    role: role // member, maintener
  }}).then(response => {
    return response.data;
  });
}

module.exports = {
  createOrganization: createOrganization,
  addOrganizationMembership: addOrganizationMembership
};
/*
# Users features

## Setup

```javascript
const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;
const users = require('../libs/features/users');


let githubCli = new GitHubClient({
  baseUri: "http://github.at.home/api/v3",
  token: process.env.TOKEN_GHITHUB_ENTERPRISE
}, users); //<-- add users features
```
*/

/*
## fetchUser

- parameter: `handle`
- return: `Promise`

### Description

`fetchUser` gets the information of a user (`handle`)

*/
function fetchUser({handle}) { // get user data
  return this.getData({path:`/users/${handle}`})
    .then(response => {
      return response.data;
    });
}

/*
## suspendUser

- parameter: `handle`
- return: `Promise`

### Description

`suspendUser` suspends a user (`handle`)

*/
function suspendUser({handle}) { //https://developer.github.com/v3/users/administration/#suspend-a-user
  this.headers["Content-Length"] = 0;
  return this.putData({path:`/users/${handle}/suspended`, data:null})
    .then(response => {
      delete this.headers["Content-Length"];
      return response
    })
}

/*
## unsuspendUser

- parameter: `handle`
- return: `Promise`

### Description

`unsuspendUser` cancels a user suspension (`handle`)

*/
function unsuspendUser({handle}) {
  return this.deleteData({path:`/users/${handle}/suspended`})
    .then(response => {
      delete this.headers["Content-Length"];
      return response
    })
}

module.exports = {
  fetchUser: fetchUser,
  suspendUser: suspendUser,
  unsuspendUser: unsuspendUser
};


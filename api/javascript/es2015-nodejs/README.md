# GitHub API + ES2015 + node.js

## Setup

- see the `package.json` of the `es2015-nodejs` directory
- type `npm install`
- you need the content of `libs/*`


## Use `/libs/GitHubClient.js`

This library can work with :octocat:.com and :octocat: Enterprise

### Create a GitHub client

- First, go to your GitHub profile settings and define a **Personal access token** (https://github.com/settings/tokens)
- Then, add the token to the environment variables (eg: `export TOKEN_GITHUB_DOT_COM=token_string`)
- Now you can get the token like that: `process.env.TOKEN_GITHUB_DOT_COM`

```javascript
const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;

let githubCliEnterprise = new GitHubClient({
  baseUri: "http://github.at.home/api/v3",
  token: process.env.TOKEN_GHITHUB_ENTERPRISE
});

let githubCliDotCom = new GitHubClient({
  baseUri:"https://api.github.com",
  token: process.env.TOKEN_GITHUB_DOT_COM
});

```

- if you use GitHub Enterprise, `baseUri` has to be set with `http(s)://your_domain_name/api/v3`
- if you use GitHub.com, `baseUri` has to be set with `https://api.github.com`

### Use the GitHub client

For example, you want to get the information about a user:
(see https://developer.github.com/v3/users/#get-a-single-user)

```javascript
let githubCliEnterprise = new GitHubClient({
  baseUri:"http://github.at.home/api/v3",
  token:process.env.TOKEN_GHITHUB_ENTERPRISE
});

var handle = "k33g";
githubCliEnterprise.getData({path:`/users/${handle}`})
  .then(response => {
    console.log(response.data);
  });
```

## The easier way: adding features

You can add "features" to `GitHubClient` (like traits):

```javascript
const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;
const octocat = require('../libs/features/octocat');
const users = require('../libs/features/users');

// add octocat and users features to GitHubClient
let githubCli = new GitHubClient({
  baseUri:"http://github.at.home/api/v3",
  token:process.env.TOKEN_GHITHUB_ENTERPRISE
}, octocat, users);

githubCli.octocat()
  .then(data => {
    // display the Zen of Octocat
    console.log(data);
  })

githubCli.fetchUser({handle:'k33g'})
  .then(user => {
    // all about @k33g
    console.log(user);
  })

```

## Recipes (and features)

See the `/recipes` directory (more samples to come)

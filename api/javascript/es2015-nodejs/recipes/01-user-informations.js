/**
 * Get GitHub user informations
 */

const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;
const users = require('../libs/features/users');


let githubCli = new GitHubClient({
  baseUri:"http://github.at.home/api/v3",
  token:process.env.TOKEN_GHITHUB_ENTERPRISE
}, users);


githubCli.fetchUser({handle:'k33g'})
  .then(user => {
  console.log(user);
  })
  .catch(error => {
    console.log("error", error)
  });


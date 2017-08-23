/**
 * Suspend user
 */

const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;
const users = require('../libs/features/users');


let githubCli = new GitHubClient({
  baseUri:"http://github.at.home/api/v3",
  token:process.env.TOKEN_GHITHUB_ENTERPRISE
}, users);


githubCli.suspendUser({handle:'ripley'})
  .then(resp => {
  console.log(resp);
  })
  .catch(error => {
    console.log("error", error)
  });


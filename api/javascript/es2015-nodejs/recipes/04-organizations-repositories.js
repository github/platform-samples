/**
 * Organizations & Repositories
 */

const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;
const repositories = require('../libs/features/repositories');
const organizations = require('../libs/features/organizations');


let githubCli = new GitHubClient({
  baseUri:"http://github.at.home/api/v3",
  token:process.env.TOKEN_GHITHUB_ENTERPRISE
}
, repositories
, organizations);

// Create an organization
githubCli.createOrganization({
  login:'ZeiraCorp',
  admin:'k33g',
  profile_name:'Zeira Corporation'
}).then(orga => {
  console.log(orga);
  // Create a repository for these organization
  githubCli.createPublicOrganizationRepository({
    name:"toys",
    description:"my little repo",
    organization:"ZeiraCorp"
  }).then(repo => {
    console.log(repo)
  })
});





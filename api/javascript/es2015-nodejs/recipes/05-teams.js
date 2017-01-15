/**
 * Teams
 */

const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;
const teams = require('../libs/features/teams');

let githubCli = new GitHubClient({
  baseUri:"http://github.at.home/api/v3",
  token:process.env.TOKEN_GHITHUB_ENTERPRISE
}, teams);


githubCli.createTeam({
  org: 'ZeiraCorp',
  name: 'DreamTeam',
  description: 'the dream team',
  repo_names:[
    'ZeiraCorp/toys',
    'ZeiraCorp/tools'
  ],
  privacy: 'closed',
  permission:'admin'
}).then(team => {
  console.log(team)
  // Add members to team of an organization
  githubCli.addTeamMembership({
    teamId: team.id,
    userName: 'spocky',
    role: 'maintener'
  }).then(results=>console.log(results))

  githubCli.addTeamMembership({
    teamId: team.id,
    userName: 'jeanlouc',
    role: 'maintener'
  }).then(results=>console.log(results))

  githubCli.addTeamMembership({
    teamId: team.id,
    userName: 'k33g',
    role: 'maintener'
  }).then(results=>console.log(results))
}).catch(error => {
  console.log("error", error)
});








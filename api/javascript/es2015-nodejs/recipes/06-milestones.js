/**
 * Milestones
 */

const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;
const milestones = require('../libs/features/milestones');

let githubCli = new GitHubClient({
  baseUri:"http://github.at.home/api/v3",
  token:process.env.TOKEN_GHITHUB_ENTERPRISE
}, milestones);

githubCli.createMilestone({
  title: 'Inception',
  state: 'open',
  description: 'A discover phase, where an initial problem statement and functional requirements are created.',
  due_on: '2016-11-01T09:00:00Z',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(milestone => console.log(milestone));

githubCli.createMilestone({
  title: 'Elaboration',
  state: 'open',
  description: 'The product vision and architecture are defined, construction cycles are planned.',
  due_on: '2016-12-01T09:00:00Z',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(milestone => console.log(milestone));

githubCli.createMilestone({
  title: 'Construction',
  state: 'open',
  description: 'The software is taken from an architectural baseline to the point where it is ready to make the transition to the user community.',
  due_on: '2017-01-01T09:00:00Z',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(milestone => console.log(milestone));

githubCli.createMilestone({
  title: 'Transition',
  state: 'open',
  description: "The software is turned into the hands of the user's community.",
  due_on: '2017-02-01T09:00:00Z',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(milestone => console.log(milestone));


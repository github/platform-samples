/**
 * Labels
 */

const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;
const labels = require('../libs/features/labels');

let githubCli = new GitHubClient({
  baseUri:"http://github.at.home/api/v3",
  token:process.env.TOKEN_GHITHUB_ENTERPRISE
}, labels);

githubCli.createLabel({
  name: 'point: 1',
  color: 'bfdadc',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(label => console.log(label));

githubCli.createLabel({
  name: 'point: 2',
  color: 'd4c5f9',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(label => console.log(label));

githubCli.createLabel({
  name: 'point: 3',
  color: 'c5def5',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(label => console.log(label));

githubCli.createLabel({
  name: 'point: 5',
  color: '1d76db',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(label => console.log(label));

githubCli.createLabel({
  name: 'point: 8',
  color: '006b75',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(label => console.log(label));

githubCli.createLabel({
  name: 'point: 13',
  color: '0e8a16',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(label => console.log(label));

githubCli.createLabel({
  name: 'point: 21',
  color: '5319e7',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(label => console.log(label));

// priority
githubCli.createLabel({
  name: 'priority: high',
  color: 'd93f0b',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(label => console.log(label));

githubCli.createLabel({
  name: 'priority: highest',
  color: 'b60205',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(label => console.log(label));

githubCli.createLabel({
  name: 'priority: low',
  color: 'fbca04',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(label => console.log(label));

githubCli.createLabel({
  name: 'priority: lowest',
  color: 'fef2c0',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(label => console.log(label));

githubCli.createLabel({
  name: 'priority: medium',
  color: 'f9d0c4',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(label => console.log(label));

// type

githubCli.createLabel({
  name: 'type: bug',
  color: 'd93f0b',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(label => console.log(label));

githubCli.createLabel({
  name: 'type: chore',
  color: 'fbca04',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(label => console.log(label));

githubCli.createLabel({
  name: 'type: feature',
  color: '1d76db',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(label => console.log(label));

githubCli.createLabel({
  name: 'type: infrastructure',
  color: '5319e7',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(label => console.log(label));

githubCli.createLabel({
  name: 'type: performance',
  color: '006b75',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(label => console.log(label));

githubCli.createLabel({
  name: 'type: refactor',
  color: 'c2e0c6',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(label => console.log(label));

githubCli.createLabel({
  name: 'type: tests',
  color: 'e99695',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(label => console.log(label));

githubCli.createLabel({
  name: 'type: implementation',
  color: '000000',
  owner: 'ZeiraCorp', // organization in this case
  repository: 'toys'
}).then(label => console.log(label));


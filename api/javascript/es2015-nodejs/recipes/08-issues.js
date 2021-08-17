/**
 * Issues, comments and reactions
 */

const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;
const issues = require('../libs/features/issues');

let githubCli = new GitHubClient({
  baseUri:"http://github.at.home/api/v3",
  token:process.env.TOKEN_GHITHUB_ENTERPRISE
}, issues);

let babs = new GitHubClient({
  baseUri:"http://github.at.home/api/v3",
  token:process.env.TOKEN_GHE_27_BABS
}, issues);

let buster = new GitHubClient({
  baseUri:"http://github.at.home/api/v3",
  token:process.env.TOKEN_GHE_27_BUSTER
}, issues);

let issueBody=`
## I've got a problem

> this a WIP

:octocat: :heart:
`;

githubCli.createIssue({
  title: "Huston?",
  body: issueBody,
  labels: ["point: 21", "priority: high", "type: bug"],
  milestone: 1,
  assignees: ["k33g"],
  owner: 'ZeiraCorp',
  repository: 'toys'
}).then(issue => {

  babs.addIssueReaction({
    owner: 'ZeiraCorp'
    , repository: 'toys'
    , number: issue.number
    , content: "hooray"
  }).then(res => console.log(res))
    .catch(err => console.log("err", err))

  babs.addIssueComment({
      owner: 'ZeiraCorp'
    , repository: 'toys'
    , number: issue.number
    , body: [
      "Hey @k33g :wave:!"
      , "It's a nice issue"
      , ":octocat: :heart:"
    ].join('\n')
  }).then(comment => {

    buster.addIssueCommentReaction({
      owner: 'ZeiraCorp'
      , repository: 'toys'
      , id: comment.id
      , content: "+1"
    })

  }).catch(err => console.log("err", err))

});








/**
 * Pull Request
 */

const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;
const contents = require('../libs/features/contents');
const refs = require('../libs/features/refs');
const pullrequests = require('../libs/features/pullrequests');

let githubCli = new GitHubClient({
  baseUri:"http://github.at.home/api/v3",
  token:process.env.TOKEN_GHITHUB_ENTERPRISE
}
  , contents
  , refs
  , pullrequests
);

let optionsBranch = {
    branch: "wip-killer-feature"
  , from: "master"
  , owner: "ZeiraCorp"
  , repository: "toys"
};

let optionsFile = Object.assign({
  file:"docs/hello-worls=d.md"
  , message: "my hello world file :octocat:"
  , content:[
    '# Hello World!'
    , '> WIP'
    , 'this is a test'
    , '## And ...'
    , '*to be continued* ...'
  ].join('\n')
}, optionsBranch);

let optionsPR = {
    title: "!!!Hey, I've a great idea!"
  , body: "It's amazing!"
  , head: optionsBranch.branch
  , base: optionsBranch.from
  , owner: optionsBranch.owner
  , repository: optionsBranch.repository
};

githubCli.createBranch(optionsBranch)
  .then(res => {
    githubCli.createFile(optionsFile)
      .then(res => {
        githubCli.createPullRequest(optionsPR)
          .then(res => {
            console.log("PR OK")
          })
      })
  });

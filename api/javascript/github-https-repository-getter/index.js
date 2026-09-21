#!/usr/bin/env node

const chalk = require('chalk');
const clear = require('clear');
const figlet = require('figlet');

const files = require('./lib/files');
const inquirer = require('./lib/inquirer');
const github = require('./lib/github');
const CLI = require('clui');
var Spinner = CLI.Spinner;

const run = async () => {
  clear();

  console.log(
    chalk.yellow(
      figlet.textSync('GitHub Repo Getter', {
        horizontalLayout: 'full'
      })
    )
  );

  const gitHubMeta = await inquirer.askGithubMeta();
  const spiner = new Spinner('Retrieving your Project, please wait...');
  spiner.start();

  github.getRepo(gitHubMeta, spiner).then(function(repo) {
    console.log("Got Project: ", gitHubMeta.repo)
    spiner.stop();
  })
}

run();

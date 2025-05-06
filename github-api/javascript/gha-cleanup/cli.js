#!/usr/bin/env node

const program = require("commander");
const prettyBytes = require("pretty-bytes");
const chalk = require("chalk");
const _ = require("lodash");
const moment = require("moment");
var inquirer = require("inquirer");
const Octokit = require("@octokit/rest");

const dotenv = require("dotenv");

dotenv.config();

program.option(
  "-t, --token <PAT>",
  "Your GitHub PAT (leave blank for prompt or set $GH_PAT)"
);
program.option(
  "-u, --user <username>",
  "Your GitHub username (leave blank for prompt or set $GH_USER)"
);
program.option("-r, --repo <repository>", "Repository name");

program.parse(process.argv);
const showArtifacts = async ({ owner, repo, PAT }) => {
  var loader = ["/ Loading", "| Loading", "\\ Loading", "- Loading"];
  var i = 4;
  var ui = new inquirer.ui.BottomBar({ bottomBar: loader[i % 4] });

  const loadingInterval = setInterval(() => {
    ui.updateBottomBar(loader[i++ % 4]);
  }, 200);

  const octokit = new Octokit({
    auth: PAT
  });

  const prefs = { owner, repo };
  ui.log.write(`${chalk.dim("[1/3]")} 🔍 Getting list of workflows...`);

  const {
    data: { workflows }
  } = await octokit.actions.listRepoWorkflows({ ...prefs });

  let everything = {};

  ui.log.write(`${chalk.dim("[2/3]")} 🏃‍♀️ Getting list of workflow runs...`);

  let runs = await workflows.reduce(async (promisedRuns, w) => {
    const memo = await promisedRuns;

    const {
      data: { workflow_runs }
    } = await octokit.actions.listWorkflowRuns({ ...prefs, workflow_id: w.id });

    everything[w.id] = {
      name: w.name,
      id: w.id,
      updated_at: w.updated_at,
      state: w.updated_at,
      runs: workflow_runs.reduce(
        (r, { id, run_number, status, conclusion, html_url }) => {
          return {
            ...r,
            [id]: {
              id,
              workflow_id: w.id,
              run_number,
              status,
              conclusion,
              html_url,
              artifacts: []
            }
          };
        },
        {}
      )
    };

    if (!workflow_runs.length) return memo;
    return [...memo, ...workflow_runs];
  }, []);

  ui.log.write(
    `${chalk.dim(
      "[3/3]"
    )} 📦 Getting list of artifacts for each run... (this may take a while)`
  );

  let all_artifacts = await runs.reduce(async (promisedArtifact, r) => {
    const memo = await promisedArtifact;

    const {
      data: { artifacts }
    } = await octokit.actions.listWorkflowRunArtifacts({
      ...prefs,
      run_id: r.id
    });

    if (!artifacts.length) return memo;

    const run_wf = _.find(everything, wf => wf.runs[r.id] != undefined);
    if (run_wf && everything[run_wf.id]) {
      everything[run_wf.id].runs[r.id].artifacts = artifacts;
    }

    return [...memo, ...artifacts];
  }, []);

  let output = [];
  _.each(everything, wf => {
    _.each(wf.runs, ({ run_number, artifacts }) => {
      _.each(artifacts, ({ id, name, size_in_bytes, created_at }) => {
        output.push({
          name,
          artifact_id: id,
          size: prettyBytes(size_in_bytes),
          size_in_bytes,
          created: moment(created_at).format("dddd, MMMM Do YYYY, h:mm:ss a"),
          created_at,
          run_number,
          workflow: wf.name
        });
      });
    });
  });

  const out = _.orderBy(output, ["size_in_bytes"], ["desc"]);
  clearInterval(loadingInterval);

  inquirer
    .prompt([
      {
        type: "checkbox",
        name: "artifact_ids",
        message: "Select the artifacts you want to delete",
        choices: output.map((row, k) => ({
          name: `${row.workflow} - ${row.name}, ${row.size} (${row.created}, ID: ${row.artifact_id}, Run #: ${row.run_number})`,
          value: row.artifact_id
        }))
      }
    ])
    .then(answers => {
      if (answers.artifact_ids.length == 0) {
        process.exit();
      }

      inquirer
        .prompt([
          {
            type: "confirm",
            name: "delete",
            message: `You are about to delete ${answers.artifact_ids.length} artifacts permanently. Are you sure?`
          }
        ])
        .then(confirm => {
          if (!confirm.delete) process.exit();

          answers.artifact_ids.map(aid => {
            octokit.actions
              .deleteArtifact({ ...prefs, artifact_id: aid })
              .then(r => {
                console.log(
                  r.status === 204
                    ? `${chalk.green("[OK]")} Artifact with ID ${chalk.dim(
                        aid
                      )} deleted`
                    : `${chalk.red("[ERR]")} Artifact with ID ${chalk.dim(
                        aid
                      )} could not be deleted.`
                );
              })
              .catch(e => {
                console.error(e.status, e.message);
              });
          });
        });
    });
};

inquirer
  .prompt([
    {
      type: "password",
      name: "PAT",
      message: "What's your GitHub PAT?",
      default: function() {
        return program.token || process.env.GH_PAT;
      }
    },
    {
      type: "input",
      name: "owner",
      message: "Your username?",
      default: function() {
        return program.user || process.env.GH_USER;
      }
    },
    {
      type: "input",
      name: "repo",
      message: "Which repository?",
      default: function() {
        return program.repo;
      }
    }
  ])
  .then(answers => {
    showArtifacts({ ...answers });
  });

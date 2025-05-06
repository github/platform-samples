#!/usr/bin/env node

const program = require("commander");
const chalk = require("chalk");
const _ = require("lodash");
var inquirer = require("inquirer");
const Octokit = require("@octokit/rest");
const dotenv = require("dotenv");

const state = {
  teamExists: false,
  teamId: 0,
  teamUrl: null,
  teamSlug: null
};

var octokit;

dotenv.config();

program.option(
  "-t, --token <PAT>",
  "Your GitHub PAT (leave blank for prompt or set $GH_PAT)",
  process.env.GH_PAT
);
program.option(
  "-u, --user <username>",
  "Your GitHub username (leave blank for prompt or set $GH_USER)",
  process.env.GH_USER
);
program.option(
  "-o, --org <organization>",
  "Organization name (leave blank for prompt or set $GH_ORG)",
  process.env.GH_ORG
);

program.option("-s, --slug <team-slug>");

program.parse(process.argv);

const die = msg => {
  const ui = new inquirer.ui.BottomBar();
  ui.log.write(`${chalk.red("[ERROR]")} ${msg}`);
  process.exit(1);
};

const findTeam = async ({ owner, org, team }) => {
  const ui = new inquirer.ui.BottomBar();

  ui.log.write(
    `${chalk.dim("[1/3]")} Verifying team ${chalk.green(
      `${org}/${team}`
    )} exists...`
  );

  try {
    var { data } = await octokit.teams.getByName({ org, team_slug: team });
  } catch (e) {
    if (e.status === 404) {
      state.teamExists = false;
    } else {
      die(e.message);
    }
  }

  if (
    _.get(data, "organization", false) &&
    _.get(data, "organization.login", false) === org
  ) {
    state.teamExists = true;
    state.teamUrl = data.html_url;
    state.teamSlug = data.slug;
  }

  if (state.teamExists) {
    ui.log.write(`${chalk.dim("[2/3]")} Team ${chalk.green(team)} found.`);
  }
};

async function createTeam({ owner, org, team }) {
  if (state.teamExists) return;

  const ui = new inquirer.ui.BottomBar();
  ui.log.write(`${chalk.dim("[2/3]")} Team ${chalk.green(team)} not found. `);

  await inquirer
    .prompt([
      {
        type: "confirm",
        name: "createTeam",
        message: `Create a new team now?`
      },
      {
        type: "input",
        name: "newTeamName",
        message: "Name of the team",
        default: () => team,
        when: ({ createTeam }) => createTeam
      },

      {
        type: "input",
        name: "teamDescription",
        message: "Team description",
        when: function({ createTeam }) {
          return createTeam;
        }
      }
    ])
    .then(async function({ createTeam, newTeamName, teamDescription }) {
      if (!createTeam) {
        process.exit();
      } else {
        try {
          var {
            data: { id, html_url, slug }
          } = await octokit.teams.create({
            org,
            name: newTeamName,
            privacy: "secret",
            description: teamDescription
          });

          state.teamExists = true;
          state.teamUrl = html_url;
          state.teamSlug = slug;
          state.teamId = id;
        } catch (e) {
          die(e.message);
        }
      }
    });
}

async function inviteMembers({ org, team }) {
  const ui = new inquirer.ui.BottomBar();

  await inquirer
    .prompt([
      {
        type: "editor",
        name: "csv",
        message: "Provide a comma separated list of usernames or email"
      }
    ])
    .then(async ({ csv }) => {
      const invitees = csv.split(",").map(i => i.trim());

      ui.log.write(
        `${chalk.dim("[3/3]")} Sending invitation to ${chalk.yellow(
          invitees.length
        )} users:`
      );

      ui.log.write(chalk.yellow("- " + invitees.join("\n- ")));

      const invites = await invitees.reduce(async (promisedRuns, i) => {
        const memo = await promisedRuns;

        if (i.indexOf("@") > -1) {
          // assume valid email
          const res = await octokit.orgs.createInvitation({
            org,
            team_ids: [state.teamId],
            email: i
          });
        } else {
          // assume valid username
          const res = await octokit.teams.addOrUpdateMembershipInOrg({
            org,
            team_slug: state.teamSlug,
            username: i
          });
        }

        // TODO what to return?
        return memo;
      }, []);

      ui.log.write(`${chalk.dim("[OK]")} Done. Review invitations at:`);
      ui.log.write(state.teamUrl);
    });
}

inquirer
  .prompt([
    {
      type: "password",
      name: "PAT",
      message: "What's your GitHub PAT?",
      default: () => program.token
    },
    {
      type: "input",
      name: "owner",
      message: "Your username?",
      default: () => program.user
    },
    {
      type: "input",
      name: "org",
      message: "Which organization?",
      default: () => program.org
    },
    {
      type: "input",
      name: "team",
      message: "Which team?",
      suffix:
        " (provide the slug of an existing team, or the full name of the team being created)",
      validate: function(value) {
        return value.length > 3
          ? true
          : "Please provide at least 4 characters.";
      },
      default: function() {
        return program.team;
      }
    }
  ])
  .then(async function(answers) {
    octokit = new Octokit({
      auth: answers.PAT
    });

    await findTeam({ ...answers });
    await createTeam({ ...answers });
    await inviteMembers({ ...answers });

    process.exit();
  });

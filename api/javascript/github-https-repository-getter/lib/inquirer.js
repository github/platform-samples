const inquirer = require('inquirer');
const files = require('./files');



const askGithubMeta = () => {
  const metaInput = [{
      name: 'userAgent',
      type: 'input',
      message: 'Enter your GitHub Username.',
      validate: function(value) {
        if (value.length) {
          return true;
        } else {
          return 'Enter your GitHub Username.';
        }
      }
    }, {
      name: 'org',
      type: 'input',
      message: 'Enter the name of your GitHub Organization. (Found in the url)',
      validate: function(value) {
        if (value.length) {
          return true;
        } else {
          return 'Enter the name of your GitHub Organization. (Found in the url)';
        }
      }
    },
    {
      name: 'repo',
      type: 'input',
      message: 'Enter the name of your GitHub Repository. (Found in the url)',
      validate: function(value) {
        if (value.length) {
          return true;
        } else {
          return 'Enter the name of your GitHub Repository. (Found in the url)';
        }
      }
    },
    {
      name: 'branch',
      type: 'input',
      message: 'Enter the branch name of your GitHub Repository.',
      validate: function(value) {
        if (value.length) {
          return true;
        } else {
          return 'Enter the branch name of your GitHub Repository.';
        }
      }
    },
    {
      name: 'pat',
      type: 'password',
      message: 'Enter your valid GitHub Personal Access Token.',
      validate: function(value) {
        if (value.length) {
          return true;
        } else {
          return 'Enter your valid GitHub Personal Access Token.';
        }
      }
    }
  ];
  return inquirer.prompt(metaInput);
}

module.exports.askGithubMeta = askGithubMeta;

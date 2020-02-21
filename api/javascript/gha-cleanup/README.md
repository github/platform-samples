# gha-cleanup - Clean up GitHub Actions artifacts

List and delete artifacts created by GitHub Actions in your repository.
Requires a Personal Access Token with full repo permissions.

![Screenshot](screenshot.png?raw=true "Script in action")

# Instructions

```
yarn install
npm link // Optional step. Call ./cli.js instead

// Options can be supplied interactively or via flags

$ gha-cleanup --help
Usage: gha-cleanup [options]

Options:
  -t, --token <PAT>        Your GitHub PAT
  -u, --user <username>    Your GitHub username
  -r, --repo <repository>  Repository name
  -h, --help               output usage information

```

# Configuration

You can pass the PAT and username directly from the prompt. To avoid repeating yourself all the time, create a .env file in the root (don't worry, it will be ignored by git) and set:

```
$GH_PAT=<Your-GitHub-Personal-Access-Token>
$GH_USER=<Your-GitHub-Username>
```

Then you can simply invoke `gha-cleanup` and confirm the prefilled values.




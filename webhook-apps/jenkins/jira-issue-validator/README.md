## Jira issue validator
In order to use this pipeline, you will need the following plugins:

- [Pipeline](https://plugins.jenkins.io/workflow-aggregator): This plugin allows us to store our `Jenkins` _jobs_ as code, and moves away from the common understanding of Jenkins `builds` to an `Agile` and `DevOps` model
- [Pipeline: Declarative](https://plugins.jenkins.io/pipeline-model-definition): Provides the ability to write _declarative pipelines_ and add `Parallel Steps`, `Wait Conditions` and more
- [Pipeline: Basic Steps](https://plugins.jenkins.io/workflow-basic-steps): Provides many of the most commonly used classes and functions used in _Pipelines_
- [Pipeline: Job](https://plugins.jenkins.io/workflow-job): Allows us to define `Triggers` within our _Pipeline_
- [Pipeline: Utility Steps](https://plugins.jenkins.io/pipeline-utility-steps): Provides us with the ability to read config files, zip archives and files on the filesystem
- [GitHub Integration](https://plugins.jenkins.io/github-pullrequest): Provides the ability to customize pull request builds
- [Pipeline: GitHub](https://plugins.jenkins.io/pipeline-github): Allows using GitHub steps within a _Jenkinsfile_
- [GitHub](https://plugins.jenkins.io/github): Provides integration with GitHub
- [Jira Pipeline Steps](https://plugins.jenkins.io/jira-steps): Allows using Jira steps within a _Jenkinsfile_
- [Jira](https://plugins.jenkins.io/jira): Enables integration with Jira

### Configuring Jenkins

1. Log in to Jenkins and click _Manage Jenkins_
2. Click _Configure System_
3. In the **Jira Steps** section, provide the required information for connecting to your Jira server
![jenkins-setup-jira](https://user-images.githubusercontent.com/865381/39254110-587316e2-4877-11e8-93f0-9050a7144ea2.png)
4. In the **GitHub Pull Request Builder** section, fill out the connection information
![jenkins-config-gh-pull-1](https://user-images.githubusercontent.com/865381/39254113-5d8fde58-4877-11e8-81f5-fb037ae06266.png)
![jenkins-setup-gh-pull-2](https://user-images.githubusercontent.com/865381/39254114-5dacc112-4877-11e8-9a0b-f1a8643de7c0.png)

### Creating the pipeline
1. Log in to Jenkins and click _New Item_
2. Give it a name and select _Pipeline_ as the type
![jira-github-validation](https://user-images.githubusercontent.com/865381/37780888-0e1d3c88-2dc6-11e8-8cd8-4b3efc55a1f1.png)
3. Check the box to enable _GitHub Project_ and provide the URL for the repository
![jenkins-github-pr-validation](https://user-images.githubusercontent.com/865381/37780961-31ee22bc-2dc6-11e8-88a3-9bec66621840.png)
4. Check the box to trigger on _GitHub Pull Requests_
  4a. Choose _Hooks with Persisted Data_ as the **Trigger Mode*
  4b. Check the box to _Set status before build_
  4c. Add _Commit changed_ and _Pull Request Opened_ as the **Trigger Events**
![jenkins-github-integration-pr-trigger](https://user-images.githubusercontent.com/865381/37780979-38469c84-2dc6-11e8-98b2-19c06b77fcf4.png)


### Example pipeline
This pipeline functions by taking the _issue ID_ from the pull request body, performing a lookup in Jira, then setting the status of the build in GitHub based on the _transition_ in Jira.

```groovy
node {
  properties([
    [$class: 'BuildDiscarderProperty',
      strategy: [$class: 'LogRotator',
        artifactDaysToKeepStr: '',
        artifactNumToKeepStr: '',
        daysToKeepStr: '',
        numToKeepStr: '5']
    ]
  ])
  stage('Validate JIRA Issue') {
    //echo sh(returnStdout: true, script: 'env')
    // Get the issue number from the PR Title
    def prTitleJira = sh(
        script: "echo \${GITHUB_PR_TITLE}|awk {'print \$1'}",
        returnStdout: true)

    // Get the issue number from the PR Body
    def prBodyJira = sh(
        script: "echo \${GITHUB_PR_BODY}|awk {'print \$1'}",
        returnStdout: true)

    // Convert the discovered issue to a string
    def prIssue = prBodyJira.trim()

    // Validate that the issue exists in JIRA
    def issue = jiraGetIssue (
        site: "JIRA",
        idOrKey: "${prIssue}")

    // Validate the state of the ticket in JIRA
    def transitions = jiraGetIssueTransitions (
        site: "JIRA",
        idOrKey: "${prIssue}")

    // Create a variable from the issue state
    def statusId = issue.data.fields.status.statusCategory.id.toString()
    def statusName = issue.data.fields.status.statusCategory.name.toString()

    // Validate that it's in the state that we want
    if (statusId == '4') {
        setGitHubPullRequestStatus (
            context: "",
            message: "${prIssue} is in the correct status",
            state: "SUCCESS")
    } else {
        setGitHubPullRequestStatus (
            context: "",
            message: "${prIssue} is not properly prepared in JIRA. Please place it in the current sprint and begin working on it",
            state: "FAILURE")
    }
  }
}
```

### Visual status
1. Create a new file with a commit message. The Jira plugin will automatically comment on the ticket if you use the `JIRA-[number] #comment <comment>` format
![jenkins-jira-commit](https://user-images.githubusercontent.com/865381/37779241-544b8bc8-2dc2-11e8-8dd6-aaca12556ed0.png)

2. Create a new pull request, and be sure that `JIRA-[number]` is the first word in the _body_
![jenkins-jira-pr-body](https://user-images.githubusercontent.com/865381/37779286-7056832c-2dc2-11e8-9cfb-82a931d40ca0.png)

#### Ticket is not _In Progress_
![jenkins-jira-pr-check-fail](https://user-images.githubusercontent.com/865381/37779349-9480bfd8-2dc2-11e8-895a-38088692f071.png)

#### Ticket is _In Progress_
![jenkins-jira-validator-pass](https://user-images.githubusercontent.com/865381/37779337-8f198138-2dc2-11e8-915f-a28130bc02ba.png)

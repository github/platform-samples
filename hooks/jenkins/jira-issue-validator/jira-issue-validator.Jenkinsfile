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

    // Validate that it's in the state that we want... in this case, 4 = 'In Progress'
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

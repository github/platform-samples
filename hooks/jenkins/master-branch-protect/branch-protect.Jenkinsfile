node {
  properties([
    [$class: 'BuildDiscarderProperty',
      strategy: [$class: 'LogRotator',
        artifactDaysToKeepStr: '',
        artifactNumToKeepStr: '',
        daysToKeepStr: '',
        numToKeepStr: '5']
    ],
    pipelineTriggers([
      [$class: 'GenericTrigger',
        genericVariables: [
          [expressionType: 'JSONPath', key: 'repository', value: '$.repository'],
          [expressionType: 'JSONPath', key: 'organization', value: '$.organization'],
          [expressionType: 'JSONPath', key: 'sender', value: '$.sender'],
          [expressionType: 'JSONPath', key: 'ref_type', value: '$.ref_type'],
          [expressionType: 'JSONPath', key: 'master_branch', value: '$.master_branch'],
          [expressionType: 'JSONPath', key: 'branch_name', value: 'ref']
        ],
        regexpFilterText: '',
        regexpFilterExpression: ''
      ]
    ])
  ])
  // Define the payload to send to GitHub.
  // This is JSON
  def githubPayload = """{
      "required_status_checks": {
        "strict": true,
        "contexts": [
          "continuous-integration/jenkins/branch"
        ]
      },
      "enforce_admins": true,
      "required_pull_request_reviews": {
        "dismissal_restrictions": {
          "users": [
            "hollywood",
            "primetheus"
          ],
          "teams": [
            "test-team"
          ]
        },
        "dismiss_stale_reviews": true,
        "require_code_owner_reviews": true
      },
      "restrictions": {
        "users": [
          "hollywood",
          "primetheus"
        ],
        "teams": [
          "test-team"
        ]
      }
    }"""

  stage("Protect Master Branch") {
    if(env.branch_name && "${branch_name}" == "${master_branch}") {
        // The credentialsId should match yours, not this demonstration
        withCredentials([string(credentialsId: '1cf07897-ad01-4e59-9075-617ea40cf111', variable: 'githubToken')]) {
          httpRequest(
              contentType: 'APPLICATION_JSON',
              consoleLogResponseBody: true,
              customHeaders: [
                  [maskValue: true, name: 'Authorization', value: "token ${githubToken}"],
                  [name: 'Accept', value: 'application/vnd.github.loki-preview']],
              httpMode: 'PUT',
              ignoreSslErrors: true,
              requestBody: githubPayload,
              responseHandle: 'NONE',
              url: "${repository_url}/branches/${repository_default_branch}/protection")
        }
    } else {
        sh(name: "Skip", script: 'echo "Move along, nothing to see here"')
    }
  }
}

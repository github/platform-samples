## Getting started
This example will take action based on webhooks received from Jira. The actions demonstrated here are:

1. Create a `branch` in GitHub when a `Version` is _created_ in Jira
2. Create a `release` in GitHub when a `Version` is _released_ in Jira

Projects in Jira are mapped to repositories in GitHub based on a `.github/jira-workflow.yml` file and can be altered to suit your needs

### Plugins
In order to configure our Jenkins instance to receive `webhooks` and process them for this example, while storing our [Pipeline as Code](https://jenkins.io/solutions/pipeline), we will need to install a few plugins.

- [Pipeline](https://plugins.jenkins.io/workflow-aggregator): This plugin allows us to store our `Jenkins` _jobs_ as code, and moves away from the common understanding of Jenkins `builds` to an `Agile` and `DevOps` model
- [Pipeline: Declarative](https://plugins.jenkins.io/pipeline-model-definition): Provides the ability to write _declarative pipelines_ and add `Parallel Steps`, `Wait Conditions` and more
- [Pipeline: Basic Steps](https://plugins.jenkins.io/workflow-basic-steps): Provides many of the most commonly used classes and functions used in _Pipelines_
- [Pipeline: Job](https://plugins.jenkins.io/workflow-job): Allows us to define `Triggers` within our _Pipeline_
- [Pipeline: Utility Steps](https://plugins.jenkins.io/pipeline-utility-steps): Provides us with the ability to read config files, zip archives and files on the filesystem
- [Build with Parameters](https://plugins.jenkins.io/build-with-parameters): Allows us to provide parameters to our pipeline
- [Generic Webhook Trigger](https://plugins.jenkins.io/generic-webhook-trigger): This plugin allows any webhook to trigger a build in Jenkins with variables contributed from the JSON/XML. We'll use this plugin instead of a _GitHub specific_ plugin because this one allows us to trigger on _any_ webhook, not just `pull requests` and `commits`
- [HTTP Request](https://plugins.jenkins.io/http_request): This plugin allows us to send HTTP requests (`POST`,`GET`,`PUT`,`DELETE`) with parameters to a URL
- [Jira Pipeline Steps](https://plugins.jenkins.io/jira-steps): Allows using Jira steps within a _Jenkinsfile_
- [Jira](https://plugins.jenkins.io/jira): Enables integration with Jira
- [Credentials Binding](https://plugins.jenkins.io/credentials-binding): Allows credentials to be bound to environment variables for use from miscellaneous build steps.
- [Credentials](https://plugins.jenkins.io/credentials): This plugin allows you to store credentials in Jenkins.

### Setting up the repo

This example pipeline will read the workflow settings from a YAML file in the `.github` directory of the repository where the pipeline lives, _not_ the repository where the code for your project lives. This particular example is a standalone Jenkins pipeline that will be triggered by multiple projects/orgs.

<details><summary>Sample .github/jira-workflow.yml</summary>

```yaml
# The list of Jira projects that we care about 
# will be keys under 'project'
project:
    # The name of the project in Jira, not the key.
    # if we want the key we can certainly update the
    # pipeline to use that instead
  - name: GitHub-Demo
    # The name of the org in GitHub that will be mapped
    # to this project. We cannot use a list here, since
    # we will use a list for the repos
    org: GitHub-Demo
    # A list of repositories that are tied to this project.
    # Each repo here will get a branch matching the version
    repos: 
      - sample-core
      - sample-api
      - sample-ui
```
</details>

### Getting Jenkins set up
Before getting started with the pipeline you'll need to setup a few things.

1. Create a `username`/`password` credential which uses your GitHub token
2. Create a `username`/`password` credential which has access to Jira
3. Create a Jira configuration in `Settings`


This demonstration will make use of the [Declarative Pipeline](https://jenkins.io/doc/book/pipeline/syntax) syntax for Jenkins, and not the less structured _advanced scripting_ syntax. So, in getting started we'll note a few things. 

First, because we're dynamically generating parallel steps, we'll need to declare our variables _outside_ the pipeline so we don't hit errors when assigning values to them.

```groovy
def settings
def projectInfo
def githubUrl = "https://api.github.com/"
// This is an array we'll use for dynamic parallization
def repos = [:]
```

Once you've declared them, some with values you won't change and some with no values (we'll set them dynamically), let's enable some debug output so we can test our pipeline and adjust it for the things we need. **This step is optional, but will help you extend this example.**

```groovy
node {
  echo sh(returnStdout: true, script: 'env')
}
```

Now we can begin the pipeline itself

```groovy
pipeline {
```

#### Setting up the triggers
The *Generic Webhook Trigger* plugin makes use of a token to differentiate pipelines. You can generate a generic token for this pipeline by running `uuidgen` at the command line on a Unix system, or `New-Guid` in PowerShell. 

##### Bash
```bash
Shenmue:~ primetheus$ uuidgen
6955F09B-EF96-467F-82EB-A35997A0C141
```
##### Powershell
```powershell
PS /Users/primetheus> New-Guid
b92bd80d-375d-4d85-8ba5-0c923e482262
```

Once you have generated your unique ID, add the token to the pipeline as a trigger. We'll capture a few variables about the webhook we'll receive as well, and use them later in the pipeline

```groovy
  triggers {
    GenericTrigger(
      genericVariables: [
        [key: 'event', value: '$.webhookEvent'],
        [key: 'version', value: '$.version'],
        [key: 'projectId', value: '$.version.projectId'],
        [key: 'name', value: '$.version.name'],
        [key: 'description', value: '$.version.description']
      ],

      causeString: 'Triggered on $ref',
      // This token is arbitrary, but is used to trigger this pipeline.
      // Without a token, ALL pipelines that use the Generic Webhook Trigger
      // plugin will trigger 
      token: 'b92bd80d-375d-4d85-8ba5-0c923e482262',
      printContributedVariables: true,
      printPostContent: true,
      silentResponse: false,
      regexpFilterText: '',
      regexpFilterExpression: ''
    )
  }
```

#### Creating our stages
Once we have the triggers created, let's begin creating our [Stages](https://jenkins.io/doc/book/pipeline/syntax/#stages) for the pipeline.

First, open the `Stages` section

```groovy
stages {
```

Then let's read our YAML file from the repo

```groovy
    stage('Get our settings') {
      steps {
        script {
          try {
            settings = readYaml(file: '.github/jira-workflow.yml')
          } catch(err) {
            echo "Please create .github/jira-workflow.yml"
            throw err
          }
        }
      }
    }
```

Once we've read the settings file (or aborted because one doesn't exist), we'll lookup the project info from Jira. The webhook will send us a Project ID, which won't really help us as humans to map, so we'll look this up once we get the payload.

```groovy
    stage('Get project info') {
      steps {
        script {
          projectInfo = jiraGetProject(idOrKey: projectId, site: 'Jira')
        }
      }
    }
```

Now we're going to apply the mapping to our repositories, and if we have multiple repos we'll generate parallel steps for each one.

```groovy
    stage('Create Release Branches') {
      when {
        expression { event == 'jira:version_created' }
      }
      steps {
        script {
          withCredentials([usernamePassword(credentialsId: '<github_credentials_id>', 
                              passwordVariable: 'githubToken', 
                              usernameVariable: 'githubUser')]) {
            settings.project.each { p ->
              if (p.name.toString() == projectInfo.data.name.toString()) {
                p.repos.each { repo ->
                  repos[repo] = {
                    node {
                      httpRequest(
                        contentType: 'APPLICATION_JSON',
                        consoleLogResponseBody: true,
                        customHeaders: [[maskValue: true, name: 'Authorization', value: "token ${githubToken}"]],
                        httpMode: 'GET',
                        outputFile: "${p.org}_${repo}_master_refs.json",
                        url: "${githubUrl}/repos/${p.org}/${repo}/git/refs/heads/master")
                      masterRefs = readJSON(file: "${p.org}_${repo}_master_refs.json")
                      payload = """{
                        "ref": "refs/heads/${name}",
                        "sha": "${masterRefs['object']['sha']}"
                      }"""
                      httpRequest(
                        contentType: 'APPLICATION_JSON',
                        consoleLogResponseBody: true,
                        customHeaders: [[maskValue: true, name: 'Authorization', value: "token ${githubToken}"]],
                        httpMode: 'POST',
                        ignoreSslErrors: false,
                        requestBody: payload,
                        responseHandle: 'NONE',
                        url: "${githubUrl}/repos/${p.org}/${repo}/git/refs")
                    }
                  }
                }
                parallel repos
              }
            }
          }
        }
      }
```

<details><summary>Sample Pipeline</summary>

```groovy
// Define variables that we'll set values to later on
// We only need to define the vars we'll use across stages
def settings
def projectInfo
// This is an array we'll use for dynamic parallization
def repos = [:]
def githubUrl = "https://github.example.com/api/v3"
//def githubUrl = "https://api.github.com/"

node {
  // useful debugging info 
  echo sh(returnStdout: true, script: 'env')
}

pipeline {
  // This can run on any agent... we can lock it down to a 
  // particular node if we have multiple nodes, but we won't here
  agent any
  triggers {
    GenericTrigger(
      genericVariables: [
        [key: 'event', value: '$.webhookEvent'],
        [key: 'version', value: '$.version'],
        [key: 'projectId', value: '$.version.projectId'],
        [key: 'name', value: '$.version.name'],
        [key: 'description', value: '$.version.description']
      ],

      causeString: 'Triggered on $ref',
      // This token is arbitrary, but is used to trigger this pipeline.
      // Without a token, ALL pipelines that use the Generic Webhook Trigger
      // plugin will trigger 
      token: '6BE4BF6E-A319-40A8-8FE9-D82AE08ABD03',
      printContributedVariables: true,
      printPostContent: true,
      silentResponse: false,
      regexpFilterText: '',
      regexpFilterExpression: ''
    )
  }
  stages {
    // We'll read our settings in this step
    stage('Get our settings') {
      steps {
        script {
          try {
            settings = readYaml(file: '.github/jira-workflow.yml')
            //sh("echo ${settings.project}")
          } catch(err) {
            echo "Please create .github/jira-workflow.yml"
            throw err
            //currentBuild.result = 'ABORTED'
            //return
            //currentBuild.rawBuild.result = Result.ABORTED //This method requires in-process script approval, but is nicer than what's running currently
          }
        }
      }
    }
    stage('Get project info') {
      steps {
        script {
          //  echo projectId
          projectInfo = jiraGetProject(idOrKey: projectId, site: 'Jira')
          //  echo projectInfo.data.name.toString()
        }
      }
    }
    stage('Create Release Branches') {
      when {
        // Let's only run this stage when we have a 'version created' event
        expression { event == 'jira:version_created' }
      }
      steps {
        script {
          // Specify our credentials to use for the steps
          withCredentials([usernamePassword(credentialsId: '<github_credentials_id>', 
                              passwordVariable: 'githubToken', 
                              usernameVariable: 'githubUser')]) {
            // Loop through our list of Projects in Jira, which will map to Orgs in GitHub.
            // We're assigning it 'p' since 'project' is assigned as part of the YAML structure
            settings.project.each { p ->
              // Only apply this release to the proper Org
              if (p.name.toString() == projectInfo.data.name.toString()) {
                // Loop through each repo in the Org
                p.repos.each { repo ->
                  // Create an array that we will use to dynamically parallelize the 
                  // actions with. 
                  repos[repo] = {
                    node {
                      // Get the master refs to create the branches from
                      httpRequest(
                        contentType: 'APPLICATION_JSON',
                        consoleLogResponseBody: true,
                        customHeaders: [[maskValue: true, name: 'Authorization', value: "token ${githubToken}"]],
                        httpMode: 'GET',
                        outputFile: "${p.org}_${repo}_master_refs.json",
                        url: "${githubUrl}/repos/${p.org}/${repo}/git/refs/heads/master")
                      // Create a variable with the values from the GET response
                      masterRefs = readJSON(file: "${p.org}_${repo}_master_refs.json")
                      // Define the payload for the GitHub API call
                      payload = """{
                        "ref": "refs/heads/${name}",
                        "sha": "${masterRefs['object']['sha']}"
                      }"""
                      // Create the new branches
                      httpRequest(
                        contentType: 'APPLICATION_JSON',
                        consoleLogResponseBody: true,
                        customHeaders: [[maskValue: true, name: 'Authorization', value: "token ${githubToken}"]],
                        httpMode: 'POST',
                        ignoreSslErrors: false,
                        requestBody: payload,
                        responseHandle: 'NONE',
                        url: "${githubUrl}/repos/${p.org}/${repo}/git/refs")
                    }
                  }
                }
                // Execute the API calls simultaneously for each repo in the Org
                parallel repos
              }
            }
          }
        }
      }
    }
    stage('Create Release') {
      when {
        // Let's only run this stage when we have a 'version created' event
        expression { event == 'jira:version_released' }
      }
      steps {
        script {
          // Specify our credentials to use for the steps
          withCredentials([usernamePassword(credentialsId: '<github_credentials_id>', 
                              passwordVariable: 'githubToken', 
                              usernameVariable: 'githubUser')]) {
            // Loop through our list of Projects in Jira, which will map to Orgs in GitHub.
            // We're assigning it 'p' since 'project' is assigned as part of the YAML structure
            settings.project.each { p ->
              // Only apply this release to the proper Org
              if (p.name.toString() == projectInfo.data.name.toString()) {
                // Loop through each repo in the Org
                p.repos.each { repo ->
                  // Create an array that we will use to dynamically parallelize the actions with. 
                  repos[repo] = {
                    node {
                      // Get the current releases
                      httpRequest(
                        contentType: 'APPLICATION_JSON',
                        consoleLogResponseBody: true,
                        customHeaders: [[maskValue: true, name: 'Authorization', value: "token ${githubToken}"]],
                        httpMode: 'GET',
                        outputFile: "${p.org}_${repo}_releases.json",
                        url: "${githubUrl}/repos/${p.org}/${repo}/releases")
                      // Create a variable with the values from the GET response
                      releases = readJSON(file: "${p.org}_${repo}_releases.json")
                      // Define the payload for the GitHub API call
                      def payload = """{
                        "tag_name": "${name}",
                        "target_commitish": "${name}",
                        "name": "${name}",
                        "body": "${description}",
                        "draft": false,
                        "prerelease": false
                      }"""
                      // Create the new release
                      httpRequest(
                        contentType: 'APPLICATION_JSON',
                        consoleLogResponseBody: true,
                        customHeaders: [[maskValue: true, name: 'Authorization', value: "token ${githubToken}"]],
                        httpMode: 'POST',
                        ignoreSslErrors: false,
                        requestBody: payload,
                        responseHandle: 'NONE',
                        url: "${githubUrl}/repos/${p.org}/${repo}/releases")
                    }
                  }
                }
                // Execute the API calls simultaneously for each repo in the Org
                parallel repos
              }
            }
          }
        }
      }
    }
  }
}
```

</details>

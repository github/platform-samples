# GitHub webhooks in Jenkins
- [Installing Jenkins](#installing-jenkins)
  * [Running in Docker](#running-jenkins-in-docker)
     - [Upgrading Jenkins in Docker](#upgrading-jenkins-in-docker)
  * [Installing Jenkins on RedHat/CentOS 7](#installing-jenkins-on-redhatcentos-7)
  * [Installing Jenkins on Ubuntu/Debian](#installing-jenkins-on-ubuntudebian)
  * [Additional installation options](#additional-installation-options)
  * [Obtaining the initial password](#obtaining-the-initial-password)
     - [Docker](#docker)
     - [Linux](#linux)
  * [Completing the setup](#completing-the-setup)
- [Installing plugins](#installing-plugins)
- [Styling Jenkins](#styling-jenkins)
- [Creating the webhook](#creating-the-webhook)
- [Creating the pipeline](#creating-the-pipeline)
  * [Git credentials in Jenkins](#git-credentials-in-jenkins)
  * [Defining our actions](#defining-our-actions)
  * [Defining the payload](#defining-the-payload)
  * [Tying it all together](#tying-it-all-together)
- [Adding the pipeline to Jenkins as a webhook listener](#adding-the-pipeline-to-jenkins-as-a-webhook-listener)

# Overview
The purpose of this guide is to address a particular scenario, wherein repositories are created but no branches are protected. In this example we will utilize `Jenkins` to process _webhooks_ that GitHub sends each time a branch is created. Once the webhook is received, Jenkins will analyse the payload and make an API call back to GitHub to:

1. Protect the `master` branch. If the `master` branch is named anything but `master`, then whatever branch that is will be protected instead
2. Ensure pull request reviews are required
3. Add administrators to the repository
4. Dismiss stale pull requests
5. Require `Code Owner` reviews

In order to achieve this goal, we will enable a webhook at the _Organization_ level to trigger on `Create` actions for any existing or new repositories. We chose `Create` actions instead of `Repository` because it is possible to create a repository without initializing it, which will send a payload to Jenkins with an empty branch name, and will ultimately cause the execution to fail. Subsequently, if this happens, a new webhook will not trigger if a new `master` branch is created after the fact. Therefore, triggering on `Create` will trigger when and only when branches or tags are created, which produces the precise effect we desire in the scenario.

#### Certificates
Before getting started, ensure that you have a trusted certificate, or that you import the GitHub certificate into Jenkins. Without this step, Jenkins will fail to clone any repositories via `HTTPS`, and the webhook will likely fail as well.

## Installing Jenkins
For this instance we will be using **_Jenkins 2.x_** because of its support for storing _Pipeline as Code_ and keeping in line with the DevOps phylosophy and spirit of collaboration.

### Running Jenkins in Docker
Let's create a container in `Docker` to run Jenkins. In this demo, we want it to run as a service and behave in a _production-like_ manner. To do this, we'll utilize the following flags:

Flag | Description
--- | ---
-d | This allows the container to run as a daemon, rather than running in the foreground of your terminal
-i | This allows _interaction_ with the container
-t | This will assign a _pseudo TTY_ interface
-p | This will map ports from the host to the container
--name | Allows you to set a name so you can manage the container with a _human-readable_ reference
--restart | Determine the restart behavior. This is particularly useful when using Docker to run services. **Options:** `always`, `unless-stopped`

We'll be mapping port `8080`, naming the container `jenkins` and configuring it to restart anytime it might crash, unless we explicitly stop it with `docker stop jenkins`.

```bash
docker run -ditp 8080:8080 --restart unless-stopped --name jenkins jenkins:latest
```

#### Upgrading Jenkins in Docker
1. If the container is already running, stop the container
```bash
docker stop jenkins
```
2. Download the latest version of Jenkins
```bash
wget http://updates.jenkins-ci.org/download/war/2.89.2/jenkins.war
```
3. Copy the `war` file into the container
```bash
docker cp jenkins.war jenkins:/usr/share/jenkins/jenkins.war
```
4. Start the container
```bash
docker start jenkins
```

### Installing Jenkins on RedHat/CentOS 7
1. Add the Jenkins repository

```bash
sudo curl -C - -LR#o /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
```
```bash
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
```

2. Install OpenJDK-8 and Jenkins

```bash
yum -y install openjdk-8-jdk jenkins
```
_**Alternate Option: Oracle Java with Jenkins RPM**_
<details>

Download the Oracle Java JDK 8u152 RPM

```bash
curl -C - -LR#OH "Cookie: oraclelicense=accept-securebackup-cookie" -k http://download.oracle.com/otn-pub/java/jdk/8u152-b16/aa0333dd3019491ca4f6ddbe78cdb6d0/jdk-8u152-linux-x64.rpm
```

Download the Jenkins 2.89.2-1.1 RPM
```bash
curl -C - -LR#O -k https://pkg.jenkins.io/redhat-stable/jenkins-2.89.2-1.1.noarch.rpm
```

Install Java and Jenkins
```bash
yum -y localinstall jdk-8u152-linux-x64.rpm jenkins-2.89.2-1.1.noarch.rpm
```

</details>

### Installing Jenkins on Ubuntu/Debian
![important note](https://www.iconsdb.com/icons/download/orange/warning-16.png) **It _may_ be necessary to install `wget` if you are working with a minimal installation. If that is the case, simply run `sudo apt install wget` before running the following steps.**

1. Add the Jenkins repository

```bash
wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -
```
```bash
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
```

```bash
sudo apt-get update
```

2. Install OpenJDK-8 and Jenkins

```bash
sudo apt-get -y install openjdk-8-jre-headless jenkins
```

### Additional installation options
For more information on installing Jenkins on another operating system, or to install using the `WAR` file, please refer to [https://jenkins.io/doc/book/installing](https://jenkins.io/doc/book/installing)

### Obtaining the initial password
Now we have a running instance of Jenkins. Let's grab the administrative key, which is stored in `/var/jenkins_home/secrets/initialAdminPassword`, so we can initially configure our instance

![unlock jenkins](https://user-images.githubusercontent.com/865381/39252315-65b30e6a-4873-11e8-9855-d12bdc4ff36c.png)

#### Docker
```bash
docker exec -it jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

#### Linux
```bash
cat /var/jenkins_home/secrets/initialAdminPassword
```

The output should be something similar to `91d94f8f73df4f1c809e014fd51bb78c`, which is our initial password.

### Completing the setup
Once you've entered the password, install the suggested plugins and configure the first _admin user_.

1. Click _Install suggested plugins_
![click install suggested plugins](https://user-images.githubusercontent.com/865381/39252351-78722950-4873-11e8-9732-c311ef1897f4.png)
![plugin install status](https://user-images.githubusercontent.com/865381/39252369-80f0567e-4873-11e8-911e-0026375be005.png)
2. Create the first _admin_ user
![create first admin user](https://user-images.githubusercontent.com/865381/39252373-829958fe-4873-11e8-9abf-de69626d468b.png)
3. Click _Start using Jenkins_ to complete the setup
![finish. click start using jenkins](https://user-images.githubusercontent.com/865381/39252375-83dd970c-4873-11e8-98df-2b0d7a2a57ab.png)


## Installing plugins
In order to configure our Jenkins instance to receive `webhooks` and process them for this example, while storing our [Pipeline as Code](https://jenkins.io/solutions/pipeline), we will need to install a few plugins.

- [Pipeline](https://plugins.jenkins.io/workflow-aggregator): This plugin allows us to store our `Jenkins` _jobs_ as code, and moves away from the common understanding of Jenkins `builds` to an `Agile` and `DevOps` model
- [Pipeline: Declarative](https://plugins.jenkins.io/pipeline-model-definition): Provides the ability to write _declarative pipelines_ and add `Parallel Steps`, `Wait Conditions` and more
- [Pipeline: Basic Steps](https://plugins.jenkins.io/workflow-basic-steps): Provides many of the most commonly used classes and functions used in _Pipelines_
- [Pipeline: Job](https://plugins.jenkins.io/workflow-job): Allows us to define `Triggers` within our _Pipeline_
- [Pipeline: Utility Steps](https://plugins.jenkins.io/pipeline-utility-steps): Provides us with the ability to read config files, zip archives and files on the filesystem
- [Build with Parameters](https://plugins.jenkins.io/build-with-parameters): Allows us to provide parameters to our pipeline
- [Generic Webhook Trigger](https://plugins.jenkins.io/generic-webhook-trigger): This plugin allows any webhook to trigger a build in Jenkins with variables contributed from the JSON/XML. We'll use this plugin instead of a _GitHub specific_ plugin because this one allows us to trigger on _any_ webhook, not just `pull requests` and `commits`
- [HTTP Request](https://plugins.jenkins.io/http_request): This plugin allows us to send HTTP requests (`POST`,`GET`,`PUT`,`DELETE`) with parameters to a URL
- [Simple Theme](https://plugins.jenkins.io/simple-theme-plugin): _**OPTIONAL**_ - We'll use this plugin to make our Jenkins instance look a little nicer with a [material theme](http://afonsof.com/jenkins-material-theme/)

### Plugin installation steps
1. Click `Manage Jenkins`
2. Click `Manage Plugins`
3. Click the _Available_ tab
4. Type the name of the plugin in the _Search_ box
5. Check the box next to the plugin
6. Repeat the search and selection for each plugin
7. Click `Download now and install after restart` when all plugins have been selected
8. Check the box to `Restart Jenkins when installation is complete and no jobs are running`


![install jenkins plugins](https://user-images.githubusercontent.com/865381/39252453-a9ddf24e-4873-11e8-8202-8be8911bcbd1.gif)

## Styling Jenkins
1. Head over to the [Jenkins Material Theme Builder](http://afonsof.com/jenkins-material-theme) and choose a theme. You can even upload a custom logo for your instance.

![download jenkins material theme](https://user-images.githubusercontent.com/865381/39252474-b7beacdc-4873-11e8-8269-d7329ad1da13.gif)


2. Once you've selected and downloaded the theme, place it in the `userContent` directory of your Jenkins instance. To do this in **_Docker_**, run the following command:

```bash
docker cp jenkins-material-theme.css jenkins:/var/jenkins_home/userContent/jenkins-material-theme.css
```

3. Finally, apply the theme:

- Click _Manage Jenkins_ from the Jenkins dashboard
- Click _Configure System_
- Scroll down to the **_Theme_** section and add `/userContent/jenkins-material-theme.css` to the _URL of theme CSS_ field


![apply material theme](https://user-images.githubusercontent.com/865381/39252490-c4872066-4873-11e8-89c6-fc9829796f88.gif)

---
## Creating the webhook

The webhook that we'll create is going to be at the _Organization_, so that we can ensure that each repository created will have this webhook triggered.

In order to utilize this webhook, we'll need to create a token. This token will be unique to the _pipeline_ that we create, **_so it's important not to re-use tokens in Jenkins_**, or each pipeline that is associated with that token will be triggered when the webhook is triggered. To create our token, run the following command on _any_ unix-based system:

```bash
$ uuidgen
```

![important note](https://www.iconsdb.com/icons/download/orange/warning-16.png)  **Be sure to save this token, as we will need it when we create the pipeline in Jenkins as well!**

### Webhook settings

| Option | Value |
| --- | --- |
| **Payload URL** | `http://<jenkins_hostname>:<port>/generic-webhook-trigger/invoke?token=<token>` |
| **Content Type** | `application/json` |
| **Events** | `Create` |

![create new webhook](https://user-images.githubusercontent.com/865381/39252518-d7403f58-4873-11e8-8959-6bb04286d66c.gif)

## Creating the pipeline
### Git credentials in Jenkins
Create a credential store that will be used to checkout the Pipeline from Git. If your `Jenkinsfile` is in a _public_ repository then this credential is not necessary. It is also a good practice to provide useful descriptions when creating these credentials.

![important note](https://www.iconsdb.com/icons/download/orange/warning-16.png)  **This particular credential _must_ be a username/password credential for checking out the _Jenkinsfile_, as the _Git_ plugin currently does not support tokens for this portion. Alternately, you may use an SSH key or make the repository public**

![important note](https://www.iconsdb.com/icons/download/orange/warning-16.png) **Jenkins will store this as an _encrypted credential_ that can be called in a _pipeline_ by the credential ID.**

Since this particular pipeline is a webhook listener, it is not necessary for this user to have _write_ access to the repository. The user can safely be restricted to _read_ access without impacting the functionality.

If you have extended security settings applied you may have issues with authentication on a private repository. For that reason, it's recommended to use a _Personal Access Token_ and _SSH_ for checking out the repo.

1. Click on _Credentials_
2. Select the _Jenkins_ domain
3. Click _Global credentials (unrestricted)_
4. On the left, click _Add Credential_
5. Enter the credentials and save. The username should be _token_ if you're using a _Personal Access Token_, and the password should be the actual token

![important note](https://www.iconsdb.com/icons/download/orange/warning-16.png) **Note the ID here for using later in the pipeline**

![create jenkins credential - username, password](https://user-images.githubusercontent.com/865381/39252547-eb8cb70c-4873-11e8-9d65-6e93f73d87f9.gif)

Now we need to create a credential for Jenkins to protect a repo in GitHub.

![important note](https://www.iconsdb.com/icons/download/orange/warning-16.png)  **This must be a user in GitHub that has the ability to alter repositories in an organization!**

Log in to GitHub as the privileged user and create a _Personal Access Token_. This can be an admin specifically created for Jenkins, as the credentials will be securely stored in Jenkins.

It is also a good practice to give a useful description so that other administrators, or even yourself, can more easily maintain security as your team or organization scales.

1. Login to GitHub
2. Click _Settings_
3. Click _Developer settings_
4. Click _Personal access tokens_
5. Click _Generate token_
6. Give the token a descriptive name
7. Select the privileges required for your account

![create personal access token](https://user-images.githubusercontent.com/865381/39252589-fd3fa66c-4873-11e8-9737-1b03d4e8978f.gif)

![create jenkins credential - secret text](https://user-images.githubusercontent.com/865381/39252617-0a8db19c-4874-11e8-8698-05d898c900f3.gif)

#### Defining our actions
In this demo we'll be defining our _payload_ to execute the following actions against the **GitHub REST API**. Utilizing the _GraphQL v4 API_ is outside the scope of this project.

- Protect the `master` branch, which may or may not be named _master_. In this demo, it is named _master_
- Enforce admins
- Require `CODEOWNERS` review
- Define repository owners
- Define repository team ownership
The payload is defined in `JSON` format and will be stored in the pipeline as a _variable_

#### Defining the payload

```json
{
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
}
```

#### Processing the webhook
As the _GitHub Webhook_ is received, Jenkins needs to process the payload and we'll use some of the data as variables in our pipeline. In order to do this, we'll need to assign _variable prefixes_ to the payload so we can access the data programatically. What we need are the following:

Name | Variable | Description
--- | --- | ---
**repository** | `$.repository` | JSON object containing info about the repository
**organization** | `$.organization` | The name of the org that the repository lives in
**sender** | `$.sender` | The user that created the repo
**ref_type** | `$.ref_type` | The event type in the payload. This should be _branch_
**master_branch** | `$.master_branch` | The default branch of the repo. _This can be anything, but defaults to `master`_
**branch_name** | `ref` | The name of the branch that was just created

```groovy
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
```

#### Log rotation
We don't want to endlessly store these logs, but we can configure a retention period, or max number of logs to store. To do this, add properties to the `node { properties([ ]) }` section of the pipeline:

```groovy
    [$class: 'BuildDiscarderProperty',
      strategy: [$class: 'LogRotator',
        artifactDaysToKeepStr: '',
        artifactNumToKeepStr: '',
        daysToKeepStr: '',
        numToKeepStr: '5']
    ]
```

What the block of code specifies is:

| Setting | Value |
| --- | --- |
| Feature | Log rotation |
| Number of artifacts to keep | _unspecified_ |
| Number of days to keep artifacts | _unspecified_ |
| Number of days to keep logs | _unspecified_ |
| Number of logs to keep | 5 |

This pipeline does not generate artifacts, so the first to options will have no impact whatsoever. The number of days to keep _logs_ is also unspecified, so Jenkins will not clean up logs based on _when_ it runs, but we specify that it will only keep a total of 5 logs. This number can and should be adjusted to suit your specific needs.

#### Adding the HTTP request with credentials
Now that we've grabbed our variables, defined our payload, and set our log rotation, let's take action on the webhook. We'll need to create a `stage { }` section, match the incoming branch name to the _master branch_ name, and protect the branch if it is the master. We'll also add our credentials from our _Jenkins Credential Store_, which allows us to avoid storing usernames and passwords in our pipelines, and to keep things dynamic. See the [Jenkins documentation](https://jenkins.io/doc/pipeline/steps/credentials-binding/) for more information on credentials binding.

```groovy
withCredentials([string(credentialsId: '<credential_id>', variable: '<variable_name>')]) {
    //do something
}
```

**HTTP Request with Credentials**
>The code section below utilizes the `loki-preview` _application type_ in the header. This is a custom header type that GitHub uses for protected branches. Refer to [GitHub's documentation](https://developer.github.com/changes/2015-11-11-protected-branches-api/) for more info.

In this example, we are utilizing the **_HTTP Request_** plugin, and placing this request inside of the `withCredentials` block. This will wrap the HTTP data inside of the authentication.

```groovy
  stage("Protect Master Branch") {
    if(env.branch_name && "${branch_name}" == "${master_branch}") {
        withCredentials([string(credentialsId: '1cf07897-ad01-4e59-9975-617ea40cf111', variable: 'githubToken')]) {
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
```  

#### Tying it all together
The final result of the _Jenkins Pipeline_ is as follows, and is stored as a file called `Jenkinsfile` inside a git repo:

```groovy
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
        withCredentials([string(credentialsId: '1cf07897-ad01-4e59-9975-617ea40cf111', variable: 'githubToken')]) {
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
```

## Adding the pipeline to Jenkins as a webhook listener
Once you've created your pipeline, check it into GitHub and now we'll create the job in Jenkins. Let's create a new job, and configure it with the following settings:

Key | Value
--- | ---
Type | Pipeline
Pipeline Source | Pipeline from SCM
Additional | Build Remotely
Build Token | [_uuid_ from Creating the Webhook](#creating-the-webhook)

1. Click _New Item_
2. Give it a name
3. Select _Pipeline_ as the type and click _OK_
4. Click `Trigger builds remotely` and provide the token you created earlier with `uuidgen`. _This is a necessary step to link the token to this pipeline. Any other pipeline that uses the same token will also be triggered, so tokens should **not** be re-used_
5. Choose `Pipeline script from SCM` as the _Pipeline Definition_
6. Provide your _repository URL_
7. Choose your credentials for cloning the `Jenkinsfile`. If this is a public repo, no credentials are necessary
8. Add an _Additional Behavior_ to _Wipe out repository & force clone_, which will provide a fresh copy of the `Jenkinsfile` each time the pipeline runs
9. Save the job
10. **If this job has never been run, click _Build Now_ so it can pull down the definition**
11. _Depending on your version of Jenkins and the **Generic Webhook** plugin, you may need to re-deliver the payload the first time to ensure you don't hit a bug where it fails to read the payload_. It's a good idea to double and triple check the functionality before going live.

![create jenkins pipeline](https://user-images.githubusercontent.com/865381/39252653-1c318d56-4874-11e8-90d6-2ba21b5fa20f.gif)

## Triggering the build
Once you have the pipeline created, simply create a new repository and initialize it with some content. The creation of that first branch will trigger the webhook and execute the pipeline.

1. Login to GitHub
2. Navigate to the _Organization_ to create a repository
3. Create a repository. In this example we'll use **_demo_** as the name

![create repository](https://user-images.githubusercontent.com/865381/39252675-2c087d84-4874-11e8-9fc7-3bf6d950caf0.gif)

## The completed workflow
Once the pipeline has been triggered and completes, view the console output to see the payload and actions taken.

<details>
  <summary>Example Pipeline Output</summary>

```
Generic Cause
Obtained Jenkinsfile from git git@github-test.local:GitHub-Demo/jenkins-protect-branch.git
[Pipeline] node
Running on Jenkins in /var/jenkins_home/workspace/github-demo
[Pipeline] {
[Pipeline] properties
GenericWebhookEnvironmentContributor Received:

{"ref":"master","ref_type":"branch","master_branch":"master","description":null,"pusher_type":"user","repository":{"id":3,"name":"demo","full_name":"GitHub-Demo/demo","owner":{"login":"GitHub-Demo","id":6,"avatar_url":"https://github-test.local/avatars/u/6?","gravatar_id":"","url":"https://github-test.local/api/v3/users/GitHub-Demo","html_url":"https://github-test.local/GitHub-Demo","followers_url":"https://github-test.local/api/v3/users/GitHub-Demo/followers","following_url":"https://github-test.local/api/v3/users/GitHub-Demo/following{/other_user}","gists_url":"https://github-test.local/api/v3/users/GitHub-Demo/gists{/gist_id}","starred_url":"https://github-test.local/api/v3/users/GitHub-Demo/starred{/owner}{/repo}","subscriptions_url":"https://github-test.local/api/v3/users/GitHub-Demo/subscriptions","organizations_url":"https://github-test.local/api/v3/users/GitHub-Demo/orgs","repos_url":"https://github-test.local/api/v3/users/GitHub-Demo/repos","events_url":"https://github-test.local/api/v3/users/GitHub-Demo/events{/privacy}","received_events_url":"https://github-test.local/api/v3/users/GitHub-Demo/received_events","type":"Organization","site_admin":false},"private":false,"html_url":"https://github-test.local/GitHub-Demo/demo","description":null,"fork":false,"url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo","forks_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/forks","keys_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/keys{/key_id}","collaborators_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/collaborators{/collaborator}","teams_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/teams","hooks_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/hooks","issue_events_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/issues/events{/number}","events_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/events","assignees_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/assignees{/user}","branches_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/branches{/branch}","tags_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/tags","blobs_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/blobs{/sha}","git_tags_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/tags{/sha}","git_refs_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/refs{/sha}","trees_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/trees{/sha}","statuses_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/statuses/{sha}","languages_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/languages","stargazers_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/stargazers","contributors_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/contributors","subscribers_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/subscribers","subscription_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/subscription","commits_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/commits{/sha}","git_commits_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/commits{/sha}","comments_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/comments{/number}","issue_comment_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/issues/comments{/number}","contents_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/contents/{+path}","compare_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/compare/{base}...{head}","merges_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/merges","archive_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/{archive_format}{/ref}","downloads_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/downloads","issues_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/issues{/number}","pulls_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/pulls{/number}","milestones_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/milestones{/number}","notifications_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/notifications{?since,all,participating}","labels_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/labels{/name}","releases_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/releases{/id}","deployments_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/deployments","created_at":"2018-01-19T20:04:24Z","updated_at":"2018-01-19T20:04:24Z","pushed_at":"2018-01-19T20:04:25Z","git_url":"git://github-test.local/GitHub-Demo/demo.git","ssh_url":"git@github-test.local:GitHub-Demo/demo.git","clone_url":"https://github-test.local/GitHub-Demo/demo.git","svn_url":"https://github-test.local/GitHub-Demo/demo","homepage":null,"size":0,"stargazers_count":0,"watchers_count":0,"language":null,"has_issues":true,"has_projects":true,"has_downloads":true,"has_wiki":true,"has_pages":false,"forks_count":0,"mirror_url":null,"archived":false,"open_issues_count":0,"forks":0,"open_issues":0,"watchers":0,"default_branch":"master"},"organization":{"login":"GitHub-Demo","id":6,"url":"https://github-test.local/api/v3/orgs/GitHub-Demo","repos_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/repos","events_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/events","hooks_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/hooks","issues_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/issues","members_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/members{/member}","public_members_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/public_members{/member}","avatar_url":"https://github-test.local/avatars/u/6?","description":null},"sender":{"login":"primetheus","id":3,"avatar_url":"https://github-test.local/avatars/u/3?","gravatar_id":"","url":"https://github-test.local/api/v3/users/primetheus","html_url":"https://github-test.local/primetheus","followers_url":"https://github-test.local/api/v3/users/primetheus/followers","following_url":"https://github-test.local/api/v3/users/primetheus/following{/other_user}","gists_url":"https://github-test.local/api/v3/users/primetheus/gists{/gist_id}","starred_url":"https://github-test.local/api/v3/users/primetheus/starred{/owner}{/repo}","subscriptions_url":"https://github-test.local/api/v3/users/primetheus/subscriptions","organizations_url":"https://github-test.local/api/v3/users/primetheus/orgs","repos_url":"https://github-test.local/api/v3/users/primetheus/repos","events_url":"https://github-test.local/api/v3/users/primetheus/events{/privacy}","received_events_url":"https://github-test.local/api/v3/users/primetheus/received_events","type":"User","site_admin":true,"ldap_dn":"CN=Jared Murrell,CN=Users,DC=github-test,DC=local"}}


Contributing variables:

    repository_has_projects = true
    repository_open_issues = 0
    repository = {"id":3,"name":"demo","full_name":"GitHub-Demo/demo","owner":{"login":"GitHub-Demo","id":6,"avatar_url":"https://github-test.local/avatars/u/6?","gravatar_id":"","url":"https://github-test.local/api/v3/users/GitHub-Demo","html_url":"https://github-test.local/GitHub-Demo","followers_url":"https://github-test.local/api/v3/users/GitHub-Demo/followers","following_url":"https://github-test.local/api/v3/users/GitHub-Demo/following{/other_user}","gists_url":"https://github-test.local/api/v3/users/GitHub-Demo/gists{/gist_id}","starred_url":"https://github-test.local/api/v3/users/GitHub-Demo/starred{/owner}{/repo}","subscriptions_url":"https://github-test.local/api/v3/users/GitHub-Demo/subscriptions","organizations_url":"https://github-test.local/api/v3/users/GitHub-Demo/orgs","repos_url":"https://github-test.local/api/v3/users/GitHub-Demo/repos","events_url":"https://github-test.local/api/v3/users/GitHub-Demo/events{/privacy}","received_events_url":"https://github-test.local/api/v3/users/GitHub-Demo/received_events","type":"Organization","site_admin":false},"private":false,"html_url":"https://github-test.local/GitHub-Demo/demo","fork":false,"url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo","forks_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/forks","keys_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/keys{/key_id}","collaborators_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/collaborators{/collaborator}","teams_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/teams","hooks_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/hooks","issue_events_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/issues/events{/number}","events_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/events","assignees_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/assignees{/user}","branches_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/branches{/branch}","tags_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/tags","blobs_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/blobs{/sha}","git_tags_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/tags{/sha}","git_refs_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/refs{/sha}","trees_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/trees{/sha}","statuses_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/statuses/{sha}","languages_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/languages","stargazers_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/stargazers","contributors_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/contributors","subscribers_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/subscribers","subscription_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/subscription","commits_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/commits{/sha}","git_commits_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/commits{/sha}","comments_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/comments{/number}","issue_comment_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/issues/comments{/number}","contents_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/contents/{+path}","compare_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/compare/{base}...{head}","merges_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/merges","archive_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/{archive_format}{/ref}","downloads_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/downloads","issues_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/issues{/number}","pulls_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/pulls{/number}","milestones_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/milestones{/number}","notifications_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/notifications{?since,all,participating}","labels_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/labels{/name}","releases_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/releases{/id}","deployments_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/deployments","created_at":"2018-01-19T20:04:24Z","updated_at":"2018-01-19T20:04:24Z","pushed_at":"2018-01-19T20:04:25Z","git_url":"git://github-test.local/GitHub-Demo/demo.git","ssh_url":"git@github-test.local:GitHub-Demo/demo.git","clone_url":"https://github-test.local/GitHub-Demo/demo.git","svn_url":"https://github-test.local/GitHub-Demo/demo","size":0,"stargazers_count":0,"watchers_count":0,"has_issues":true,"has_projects":true,"has_downloads":true,"has_wiki":true,"has_pages":false,"forks_count":0,"archived":false,"open_issues_count":0,"forks":0,"open_issues":0,"watchers":0,"default_branch":"master"}
    repository_owner_url = https://github-test.local/api/v3/users/GitHub-Demo
    repository_clone_url = https://github-test.local/GitHub-Demo/demo.git
    sender_subscriptions_url = https://github-test.local/api/v3/users/primetheus/subscriptions
    repository_owner_following_url = https://github-test.local/api/v3/users/GitHub-Demo/following{/other_user}
    repository_teams_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/teams
    repository_trees_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/trees{/sha}
    repository_pulls_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/pulls{/number}
    repository_name = demo
    sender_url = https://github-test.local/api/v3/users/primetheus
    repository_has_pages = false
    repository_deployments_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/deployments
    repository_labels_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/labels{/name}
    sender_login = primetheus
    repository_svn_url = https://github-test.local/GitHub-Demo/demo
    repository_merges_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/merges
    sender = {"login":"primetheus","id":3,"avatar_url":"https://github-test.local/avatars/u/3?","gravatar_id":"","url":"https://github-test.local/api/v3/users/primetheus","html_url":"https://github-test.local/primetheus","followers_url":"https://github-test.local/api/v3/users/primetheus/followers","following_url":"https://github-test.local/api/v3/users/primetheus/following{/other_user}","gists_url":"https://github-test.local/api/v3/users/primetheus/gists{/gist_id}","starred_url":"https://github-test.local/api/v3/users/primetheus/starred{/owner}{/repo}","subscriptions_url":"https://github-test.local/api/v3/users/primetheus/subscriptions","organizations_url":"https://github-test.local/api/v3/users/primetheus/orgs","repos_url":"https://github-test.local/api/v3/users/primetheus/repos","events_url":"https://github-test.local/api/v3/users/primetheus/events{/privacy}","received_events_url":"https://github-test.local/api/v3/users/primetheus/received_events","type":"User","site_admin":true,"ldap_dn":"CN\u003dJared Murrell,CN\u003dUsers,DC\u003dgithub-test,DC\u003dlocal"}
    repository_keys_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/keys{/key_id}
    repository_events_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/events
    repository_updated_at = 2018-01-19T20:04:24Z
    sender_ldap_dn = CN=Jared Murrell,CN=Users,DC=github-test,DC=local
    repository_releases_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/releases{/id}
    repository_default_branch = master
    repository_forks = 0
    sender_repos_url = https://github-test.local/api/v3/users/primetheus/repos
    repository_assignees_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/assignees{/user}
    repository_comments_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/comments{/number}
    repository_size = 0
    organization_issues_url = https://github-test.local/api/v3/orgs/GitHub-Demo/issues
    repository_private = false
    repository_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo
    repository_owner_site_admin = false
    sender_starred_url = https://github-test.local/api/v3/users/primetheus/starred{/owner}{/repo}
    sender_organizations_url = https://github-test.local/api/v3/users/primetheus/orgs
    organization_url = https://github-test.local/api/v3/orgs/GitHub-Demo
    organization_login = GitHub-Demo
    sender_received_events_url = https://github-test.local/api/v3/users/primetheus/received_events
    repository_branches_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/branches{/branch}
    repository_contributors_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/contributors
    organization = {"login":"GitHub-Demo","id":6,"url":"https://github-test.local/api/v3/orgs/GitHub-Demo","repos_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/repos","events_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/events","hooks_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/hooks","issues_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/issues","members_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/members{/member}","public_members_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/public_members{/member}","avatar_url":"https://github-test.local/avatars/u/6?"}
    repository_owner_html_url = https://github-test.local/GitHub-Demo
    repository_issue_events_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/issues/events{/number}
    repository_git_url = git://github-test.local/GitHub-Demo/demo.git
    repository_owner_id = 6
    repository_has_downloads = true
    organization_avatar_url = https://github-test.local/avatars/u/6?
    repository_owner_gravatar_id =
    repository_statuses_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/statuses/{sha}
    repository_commits_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/commits{/sha}
    organization_events_url = https://github-test.local/api/v3/orgs/GitHub-Demo/events
    repository_owner_received_events_url = https://github-test.local/api/v3/users/GitHub-Demo/received_events
    repository_archive_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/{archive_format}{/ref}
    repository_owner_subscriptions_url = https://github-test.local/api/v3/users/GitHub-Demo/subscriptions
    sender_id = 3
    repository_owner_organizations_url = https://github-test.local/api/v3/users/GitHub-Demo/orgs
    repository_full_name = GitHub-Demo/demo
    repository_id = 3
    repository_issue_comment_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/issues/comments{/number}
    repository_collaborators_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/collaborators{/collaborator}
    repository_owner_login = GitHub-Demo
    master_branch = master
    sender_site_admin = true
    repository_archived = false
    sender_html_url = https://github-test.local/primetheus
    repository_has_issues = true
    repository_forks_count = 0
    repository_created_at = 2018-01-19T20:04:24Z
    repository_stargazers_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/stargazers
    repository_compare_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/compare/{base}...{head}
    sender_gists_url = https://github-test.local/api/v3/users/primetheus/gists{/gist_id}
    repository_stargazers_count = 0
    organization_id = 6
    repository_owner_avatar_url = https://github-test.local/avatars/u/6?
    organization_hooks_url = https://github-test.local/api/v3/orgs/GitHub-Demo/hooks
    repository_owner_type = Organization
    repository_downloads_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/downloads
    repository_owner_events_url = https://github-test.local/api/v3/users/GitHub-Demo/events{/privacy}
    sender_following_url = https://github-test.local/api/v3/users/primetheus/following{/other_user}
    repository_issues_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/issues{/number}
    sender_avatar_url = https://github-test.local/avatars/u/3?
    repository_blobs_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/blobs{/sha}
    sender_events_url = https://github-test.local/api/v3/users/primetheus/events{/privacy}
    repository_hooks_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/hooks
    repository_subscription_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/subscription
    repository_watchers_count = 0
    repository_git_tags_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/tags{/sha}
    repository_open_issues_count = 0
    repository_contents_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/contents/{+path}
    repository_notifications_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/notifications{?since,all,participating}
    sender_gravatar_id =
    repository_pushed_at = 2018-01-19T20:04:25Z
    repository_git_commits_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/commits{/sha}
    repository_has_wiki = true
    repository_watchers = 0
    sender_followers_url = https://github-test.local/api/v3/users/primetheus/followers
    repository_owner_gists_url = https://github-test.local/api/v3/users/GitHub-Demo/gists{/gist_id}
    branch_name = master
    organization_public_members_url = https://github-test.local/api/v3/orgs/GitHub-Demo/public_members{/member}
    repository_git_refs_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/refs{/sha}
    repository_subscribers_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/subscribers
    organization_members_url = https://github-test.local/api/v3/orgs/GitHub-Demo/members{/member}
    organization_repos_url = https://github-test.local/api/v3/orgs/GitHub-Demo/repos
    sender_type = User
    repository_ssh_url = git@github-test.local:GitHub-Demo/demo.git
    repository_owner_repos_url = https://github-test.local/api/v3/users/GitHub-Demo/repos
    repository_milestones_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/milestones{/number}
    repository_fork = false
    repository_languages_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/languages
    repository_tags_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/tags
    repository_html_url = https://github-test.local/GitHub-Demo/demo
    repository_owner_followers_url = https://github-test.local/api/v3/users/GitHub-Demo/followers
    ref_type = branch
    repository_forks_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/forks
    repository_owner_starred_url = https://github-test.local/api/v3/users/GitHub-Demo/starred{/owner}{/repo}


[Pipeline] stage
GenericWebhookEnvironmentContributor Received:

{"ref":"master","ref_type":"branch","master_branch":"master","description":null,"pusher_type":"user","repository":{"id":3,"name":"demo","full_name":"GitHub-Demo/demo","owner":{"login":"GitHub-Demo","id":6,"avatar_url":"https://github-test.local/avatars/u/6?","gravatar_id":"","url":"https://github-test.local/api/v3/users/GitHub-Demo","html_url":"https://github-test.local/GitHub-Demo","followers_url":"https://github-test.local/api/v3/users/GitHub-Demo/followers","following_url":"https://github-test.local/api/v3/users/GitHub-Demo/following{/other_user}","gists_url":"https://github-test.local/api/v3/users/GitHub-Demo/gists{/gist_id}","starred_url":"https://github-test.local/api/v3/users/GitHub-Demo/starred{/owner}{/repo}","subscriptions_url":"https://github-test.local/api/v3/users/GitHub-Demo/subscriptions","organizations_url":"https://github-test.local/api/v3/users/GitHub-Demo/orgs","repos_url":"https://github-test.local/api/v3/users/GitHub-Demo/repos","events_url":"https://github-test.local/api/v3/users/GitHub-Demo/events{/privacy}","received_events_url":"https://github-test.local/api/v3/users/GitHub-Demo/received_events","type":"Organization","site_admin":false},"private":false,"html_url":"https://github-test.local/GitHub-Demo/demo","description":null,"fork":false,"url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo","forks_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/forks","keys_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/keys{/key_id}","collaborators_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/collaborators{/collaborator}","teams_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/teams","hooks_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/hooks","issue_events_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/issues/events{/number}","events_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/events","assignees_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/assignees{/user}","branches_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/branches{/branch}","tags_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/tags","blobs_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/blobs{/sha}","git_tags_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/tags{/sha}","git_refs_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/refs{/sha}","trees_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/trees{/sha}","statuses_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/statuses/{sha}","languages_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/languages","stargazers_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/stargazers","contributors_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/contributors","subscribers_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/subscribers","subscription_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/subscription","commits_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/commits{/sha}","git_commits_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/commits{/sha}","comments_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/comments{/number}","issue_comment_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/issues/comments{/number}","contents_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/contents/{+path}","compare_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/compare/{base}...{head}","merges_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/merges","archive_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/{archive_format}{/ref}","downloads_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/downloads","issues_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/issues{/number}","pulls_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/pulls{/number}","milestones_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/milestones{/number}","notifications_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/notifications{?since,all,participating}","labels_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/labels{/name}","releases_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/releases{/id}","deployments_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/deployments","created_at":"2018-01-19T20:04:24Z","updated_at":"2018-01-19T20:04:24Z","pushed_at":"2018-01-19T20:04:25Z","git_url":"git://github-test.local/GitHub-Demo/demo.git","ssh_url":"git@github-test.local:GitHub-Demo/demo.git","clone_url":"https://github-test.local/GitHub-Demo/demo.git","svn_url":"https://github-test.local/GitHub-Demo/demo","homepage":null,"size":0,"stargazers_count":0,"watchers_count":0,"language":null,"has_issues":true,"has_projects":true,"has_downloads":true,"has_wiki":true,"has_pages":false,"forks_count":0,"mirror_url":null,"archived":false,"open_issues_count":0,"forks":0,"open_issues":0,"watchers":0,"default_branch":"master"},"organization":{"login":"GitHub-Demo","id":6,"url":"https://github-test.local/api/v3/orgs/GitHub-Demo","repos_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/repos","events_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/events","hooks_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/hooks","issues_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/issues","members_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/members{/member}","public_members_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/public_members{/member}","avatar_url":"https://github-test.local/avatars/u/6?","description":null},"sender":{"login":"primetheus","id":3,"avatar_url":"https://github-test.local/avatars/u/3?","gravatar_id":"","url":"https://github-test.local/api/v3/users/primetheus","html_url":"https://github-test.local/primetheus","followers_url":"https://github-test.local/api/v3/users/primetheus/followers","following_url":"https://github-test.local/api/v3/users/primetheus/following{/other_user}","gists_url":"https://github-test.local/api/v3/users/primetheus/gists{/gist_id}","starred_url":"https://github-test.local/api/v3/users/primetheus/starred{/owner}{/repo}","subscriptions_url":"https://github-test.local/api/v3/users/primetheus/subscriptions","organizations_url":"https://github-test.local/api/v3/users/primetheus/orgs","repos_url":"https://github-test.local/api/v3/users/primetheus/repos","events_url":"https://github-test.local/api/v3/users/primetheus/events{/privacy}","received_events_url":"https://github-test.local/api/v3/users/primetheus/received_events","type":"User","site_admin":true,"ldap_dn":"CN=Jared Murrell,CN=Users,DC=github-test,DC=local"}}


Contributing variables:

    repository_has_projects = true
    repository_open_issues = 0
    repository = {"id":3,"name":"demo","full_name":"GitHub-Demo/demo","owner":{"login":"GitHub-Demo","id":6,"avatar_url":"https://github-test.local/avatars/u/6?","gravatar_id":"","url":"https://github-test.local/api/v3/users/GitHub-Demo","html_url":"https://github-test.local/GitHub-Demo","followers_url":"https://github-test.local/api/v3/users/GitHub-Demo/followers","following_url":"https://github-test.local/api/v3/users/GitHub-Demo/following{/other_user}","gists_url":"https://github-test.local/api/v3/users/GitHub-Demo/gists{/gist_id}","starred_url":"https://github-test.local/api/v3/users/GitHub-Demo/starred{/owner}{/repo}","subscriptions_url":"https://github-test.local/api/v3/users/GitHub-Demo/subscriptions","organizations_url":"https://github-test.local/api/v3/users/GitHub-Demo/orgs","repos_url":"https://github-test.local/api/v3/users/GitHub-Demo/repos","events_url":"https://github-test.local/api/v3/users/GitHub-Demo/events{/privacy}","received_events_url":"https://github-test.local/api/v3/users/GitHub-Demo/received_events","type":"Organization","site_admin":false},"private":false,"html_url":"https://github-test.local/GitHub-Demo/demo","fork":false,"url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo","forks_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/forks","keys_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/keys{/key_id}","collaborators_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/collaborators{/collaborator}","teams_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/teams","hooks_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/hooks","issue_events_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/issues/events{/number}","events_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/events","assignees_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/assignees{/user}","branches_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/branches{/branch}","tags_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/tags","blobs_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/blobs{/sha}","git_tags_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/tags{/sha}","git_refs_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/refs{/sha}","trees_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/trees{/sha}","statuses_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/statuses/{sha}","languages_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/languages","stargazers_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/stargazers","contributors_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/contributors","subscribers_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/subscribers","subscription_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/subscription","commits_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/commits{/sha}","git_commits_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/commits{/sha}","comments_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/comments{/number}","issue_comment_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/issues/comments{/number}","contents_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/contents/{+path}","compare_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/compare/{base}...{head}","merges_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/merges","archive_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/{archive_format}{/ref}","downloads_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/downloads","issues_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/issues{/number}","pulls_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/pulls{/number}","milestones_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/milestones{/number}","notifications_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/notifications{?since,all,participating}","labels_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/labels{/name}","releases_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/releases{/id}","deployments_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/deployments","created_at":"2018-01-19T20:04:24Z","updated_at":"2018-01-19T20:04:24Z","pushed_at":"2018-01-19T20:04:25Z","git_url":"git://github-test.local/GitHub-Demo/demo.git","ssh_url":"git@github-test.local:GitHub-Demo/demo.git","clone_url":"https://github-test.local/GitHub-Demo/demo.git","svn_url":"https://github-test.local/GitHub-Demo/demo","size":0,"stargazers_count":0,"watchers_count":0,"has_issues":true,"has_projects":true,"has_downloads":true,"has_wiki":true,"has_pages":false,"forks_count":0,"archived":false,"open_issues_count":0,"forks":0,"open_issues":0,"watchers":0,"default_branch":"master"}
    repository_owner_url = https://github-test.local/api/v3/users/GitHub-Demo
    repository_clone_url = https://github-test.local/GitHub-Demo/demo.git
    sender_subscriptions_url = https://github-test.local/api/v3/users/primetheus/subscriptions
    repository_owner_following_url = https://github-test.local/api/v3/users/GitHub-Demo/following{/other_user}
    repository_teams_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/teams
    repository_trees_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/trees{/sha}
    repository_pulls_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/pulls{/number}
    repository_name = demo
    sender_url = https://github-test.local/api/v3/users/primetheus
    repository_has_pages = false
    repository_deployments_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/deployments
    repository_labels_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/labels{/name}
    sender_login = primetheus
    repository_svn_url = https://github-test.local/GitHub-Demo/demo
    repository_merges_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/merges
    sender = {"login":"primetheus","id":3,"avatar_url":"https://github-test.local/avatars/u/3?","gravatar_id":"","url":"https://github-test.local/api/v3/users/primetheus","html_url":"https://github-test.local/primetheus","followers_url":"https://github-test.local/api/v3/users/primetheus/followers","following_url":"https://github-test.local/api/v3/users/primetheus/following{/other_user}","gists_url":"https://github-test.local/api/v3/users/primetheus/gists{/gist_id}","starred_url":"https://github-test.local/api/v3/users/primetheus/starred{/owner}{/repo}","subscriptions_url":"https://github-test.local/api/v3/users/primetheus/subscriptions","organizations_url":"https://github-test.local/api/v3/users/primetheus/orgs","repos_url":"https://github-test.local/api/v3/users/primetheus/repos","events_url":"https://github-test.local/api/v3/users/primetheus/events{/privacy}","received_events_url":"https://github-test.local/api/v3/users/primetheus/received_events","type":"User","site_admin":true,"ldap_dn":"CN\u003dJared Murrell,CN\u003dUsers,DC\u003dgithub-test,DC\u003dlocal"}
    repository_keys_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/keys{/key_id}
    repository_events_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/events
    repository_updated_at = 2018-01-19T20:04:24Z
    sender_ldap_dn = CN=Jared Murrell,CN=Users,DC=github-test,DC=local
    repository_releases_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/releases{/id}
    repository_default_branch = master
    repository_forks = 0
    sender_repos_url = https://github-test.local/api/v3/users/primetheus/repos
    repository_assignees_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/assignees{/user}
    repository_comments_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/comments{/number}
    repository_size = 0
    organization_issues_url = https://github-test.local/api/v3/orgs/GitHub-Demo/issues
    repository_private = false
    repository_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo
    repository_owner_site_admin = false
    sender_starred_url = https://github-test.local/api/v3/users/primetheus/starred{/owner}{/repo}
    sender_organizations_url = https://github-test.local/api/v3/users/primetheus/orgs
    organization_url = https://github-test.local/api/v3/orgs/GitHub-Demo
    organization_login = GitHub-Demo
    sender_received_events_url = https://github-test.local/api/v3/users/primetheus/received_events
    repository_branches_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/branches{/branch}
    repository_contributors_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/contributors
    organization = {"login":"GitHub-Demo","id":6,"url":"https://github-test.local/api/v3/orgs/GitHub-Demo","repos_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/repos","events_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/events","hooks_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/hooks","issues_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/issues","members_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/members{/member}","public_members_url":"https://github-test.local/api/v3/orgs/GitHub-Demo/public_members{/member}","avatar_url":"https://github-test.local/avatars/u/6?"}
    repository_owner_html_url = https://github-test.local/GitHub-Demo
    repository_issue_events_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/issues/events{/number}
    repository_git_url = git://github-test.local/GitHub-Demo/demo.git
    repository_owner_id = 6
    repository_has_downloads = true
    organization_avatar_url = https://github-test.local/avatars/u/6?
    repository_owner_gravatar_id =
    repository_statuses_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/statuses/{sha}
    repository_commits_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/commits{/sha}
    organization_events_url = https://github-test.local/api/v3/orgs/GitHub-Demo/events
    repository_owner_received_events_url = https://github-test.local/api/v3/users/GitHub-Demo/received_events
    repository_archive_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/{archive_format}{/ref}
    repository_owner_subscriptions_url = https://github-test.local/api/v3/users/GitHub-Demo/subscriptions
    sender_id = 3
    repository_owner_organizations_url = https://github-test.local/api/v3/users/GitHub-Demo/orgs
    repository_full_name = GitHub-Demo/demo
    repository_id = 3
    repository_issue_comment_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/issues/comments{/number}
    repository_collaborators_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/collaborators{/collaborator}
    repository_owner_login = GitHub-Demo
    master_branch = master
    sender_site_admin = true
    repository_archived = false
    sender_html_url = https://github-test.local/primetheus
    repository_has_issues = true
    repository_forks_count = 0
    repository_created_at = 2018-01-19T20:04:24Z
    repository_stargazers_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/stargazers
    repository_compare_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/compare/{base}...{head}
    sender_gists_url = https://github-test.local/api/v3/users/primetheus/gists{/gist_id}
    repository_stargazers_count = 0
    organization_id = 6
    repository_owner_avatar_url = https://github-test.local/avatars/u/6?
    organization_hooks_url = https://github-test.local/api/v3/orgs/GitHub-Demo/hooks
    repository_owner_type = Organization
    repository_downloads_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/downloads
    repository_owner_events_url = https://github-test.local/api/v3/users/GitHub-Demo/events{/privacy}
    sender_following_url = https://github-test.local/api/v3/users/primetheus/following{/other_user}
    repository_issues_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/issues{/number}
    sender_avatar_url = https://github-test.local/avatars/u/3?
    repository_blobs_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/blobs{/sha}
    sender_events_url = https://github-test.local/api/v3/users/primetheus/events{/privacy}
    repository_hooks_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/hooks
    repository_subscription_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/subscription
    repository_watchers_count = 0
    repository_git_tags_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/tags{/sha}
    repository_open_issues_count = 0
    repository_contents_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/contents/{+path}
    repository_notifications_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/notifications{?since,all,participating}
    sender_gravatar_id =
    repository_pushed_at = 2018-01-19T20:04:25Z
    repository_git_commits_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/commits{/sha}
    repository_has_wiki = true
    repository_watchers = 0
    sender_followers_url = https://github-test.local/api/v3/users/primetheus/followers
    repository_owner_gists_url = https://github-test.local/api/v3/users/GitHub-Demo/gists{/gist_id}
    branch_name = master
    organization_public_members_url = https://github-test.local/api/v3/orgs/GitHub-Demo/public_members{/member}
    repository_git_refs_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/git/refs{/sha}
    repository_subscribers_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/subscribers
    organization_members_url = https://github-test.local/api/v3/orgs/GitHub-Demo/members{/member}
    organization_repos_url = https://github-test.local/api/v3/orgs/GitHub-Demo/repos
    sender_type = User
    repository_ssh_url = git@github-test.local:GitHub-Demo/demo.git
    repository_owner_repos_url = https://github-test.local/api/v3/users/GitHub-Demo/repos
    repository_milestones_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/milestones{/number}
    repository_fork = false
    repository_languages_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/languages
    repository_tags_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/tags
    repository_html_url = https://github-test.local/GitHub-Demo/demo
    repository_owner_followers_url = https://github-test.local/api/v3/users/GitHub-Demo/followers
    ref_type = branch
    repository_forks_url = https://github-test.local/api/v3/repos/GitHub-Demo/demo/forks
    repository_owner_starred_url = https://github-test.local/api/v3/users/GitHub-Demo/starred{/owner}{/repo}


[Pipeline] { (Protect Master Branch)
[Pipeline] withCredentials
[Pipeline] {
[Pipeline] httpRequest
HttpMethod: PUT
URL: https://github-test.local/api/v3/repos/GitHub-Demo/demo/branches/master/protection
Content-type: application/json
Authorization: *****
Accept: application/vnd.github.loki-preview
Sending request to url: https://github-test.local/api/v3/repos/GitHub-Demo/demo/branches/master/protection
Response Code: HTTP/1.1 200 OK
Response:
{"url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/branches/master/protection","required_status_checks":{"url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/branches/master/protection/required_status_checks","strict":true,"contexts":["continuous-integration/jenkins/branch"],"contexts_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/branches/master/protection/required_status_checks/contexts"},"restrictions":{"url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/branches/master/protection/restrictions","users_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/branches/master/protection/restrictions/users","teams_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/branches/master/protection/restrictions/teams","users":[{"login":"primetheus","id":3,"avatar_url":"https://github-test.local/avatars/u/3?","gravatar_id":"","url":"https://github-test.local/api/v3/users/primetheus","html_url":"https://github-test.local/primetheus","followers_url":"https://github-test.local/api/v3/users/primetheus/followers","following_url":"https://github-test.local/api/v3/users/primetheus/following{/other_user}","gists_url":"https://github-test.local/api/v3/users/primetheus/gists{/gist_id}","starred_url":"https://github-test.local/api/v3/users/primetheus/starred{/owner}{/repo}","subscriptions_url":"https://github-test.local/api/v3/users/primetheus/subscriptions","organizations_url":"https://github-test.local/api/v3/users/primetheus/orgs","repos_url":"https://github-test.local/api/v3/users/primetheus/repos","events_url":"https://github-test.local/api/v3/users/primetheus/events{/privacy}","received_events_url":"https://github-test.local/api/v3/users/primetheus/received_events","type":"User","site_admin":true,"ldap_dn":"CN=Jared Murrell,CN=Users,DC=github-test,DC=local"}],"teams":[]},"required_pull_request_reviews":{"url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/branches/master/protection/required_pull_request_reviews","dismiss_stale_reviews":true,"require_code_owner_reviews":true,"dismissal_restrictions":{"url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/branches/master/protection/dismissal_restrictions","users_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/branches/master/protection/dismissal_restrictions/users","teams_url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/branches/master/protection/dismissal_restrictions/teams","users":[{"login":"primetheus","id":3,"avatar_url":"https://github-test.local/avatars/u/3?","gravatar_id":"","url":"https://github-test.local/api/v3/users/primetheus","html_url":"https://github-test.local/primetheus","followers_url":"https://github-test.local/api/v3/users/primetheus/followers","following_url":"https://github-test.local/api/v3/users/primetheus/following{/other_user}","gists_url":"https://github-test.local/api/v3/users/primetheus/gists{/gist_id}","starred_url":"https://github-test.local/api/v3/users/primetheus/starred{/owner}{/repo}","subscriptions_url":"https://github-test.local/api/v3/users/primetheus/subscriptions","organizations_url":"https://github-test.local/api/v3/users/primetheus/orgs","repos_url":"https://github-test.local/api/v3/users/primetheus/repos","events_url":"https://github-test.local/api/v3/users/primetheus/events{/privacy}","received_events_url":"https://github-test.local/api/v3/users/primetheus/received_events","type":"User","site_admin":true,"ldap_dn":"CN=Jared Murrell,CN=Users,DC=github-test,DC=local"}],"teams":[]}},"enforce_admins":{"url":"https://github-test.local/api/v3/repos/GitHub-Demo/demo/branches/master/protection/enforce_admins","enabled":true}}
Success code from [100‥399]
[Pipeline] }
[Pipeline] // withCredentials
[Pipeline] }
[Pipeline] // stage
[Pipeline] }
[Pipeline] // node
[Pipeline] End of Pipeline
Finished: SUCCESS
```

</details>

Notice in the sample output above, the received payload is in `JSON` format, but when Jenkins processes the data it is flattened and referenced as **_Contributing Variables_**. You will find a long list of `repository_<field>` items in the data, which is the **Generic Webhook** plugin's method of mapping the keys that we specified in [our table earlier](#processing-the-webhook). If there are other keys in the `JSON` payload we receive that we want to process, simply map them in the same manner.

To verify the protection in GitHub, navigate to the repository in GitHub.

1. Click on _Settings_
2. Click on _Branches_

Notice that we already have protection on the `master` branch.

![branch protection settings](https://user-images.githubusercontent.com/865381/39252741-5022b6d0-4874-11e8-969f-1db4b4ec35cf.gif)

3. Click on _Edit_ to see the individual protection settings configured

![individual branch protection settings](https://user-images.githubusercontent.com/865381/39252951-c447c4d8-4874-11e8-99f8-6095216912da.gif)

## Conclusion
This wraps up our example. This article will hopefully empower you to automate many more tasks for your teams and company as you explore the capabilities of GitHub and Jenkins together!

# GitHub API Challenge


This is simple web service that listens for repository events to know when a repository has been deleted. When the repository is deleted a new issue is created in the cls_notification repository that notifies chadlsmith of the deletion event. 


### Prerequisites
* [Ngrok ](https://ngrok.com/download) 
* [Ruby 2.2 or higher](https://www.ruby-lang.org/en/downloads/) 
* [Sinatra](https://github.com/sinatra/sinatra) 
* A git client which is included with most modern operating systems
* [API Token](https://github.com/blog/1509-personal-api-tokens) 

### Configuration   

Before running the sample, you will need to start the following services on your machine.

#### Ngrok 
To start ngrok run the following command 

```
<ngrok_download_dir> /ngrok http 4567
```

When ngrok starts take note of the forwarding ip address it will be similar to:

```
Forwarding                    http://4554ee82.ngrok.io -> localhost:4567
```
#### Clone repository

To pull the most recent version of the sample run a git clone on the clsOrg/platform-samples repository 
```
git clone https://github.com/clsOrg/platform-samples.git
```

#### Start Application

To setup the environment to connect to your GitHub Org you will need to **update the set.env file with your api key** and execute the set.env file using the following command:

```
. ./<sample_install_dir>/platform-samples/hooks/ruby/delete-repository-event/set.env
```

To start the the samples run the following command:

```
ruby <sample_install_dir>/platform-samples/hooks/ruby/delete-repository-event/app.rb
```


## Running the test

* [Create a webhook with the following settings:](https://developer.github.com/webhooks/creating/)  
  * Payload URL = Forwarding link from ngrok with a trailing /delete-repository-event
    ```
    http://4554ee82.ngrok.io/delete-repository-event
    ```
  * Content Type = json 
  * Which events would you like to trigger this webhook = Let me select individual events
    * Repository
* [Create a sample repository:](https://help.github.com/articles/create-a-repo/)  
* [Delete the newly created repository:](https://help.github.com/articles/deleting-a-repository/)  

## Validating the test

Go to  https://github.com/clsOrg/cls_notification to validate that a new issue has been created. It should be smiilar to example below.  

```
[Restore the repository](https://github.com/stafftools/users/clsOrg/purgatory)
 @chadlsmith Please review this isue
```json
{
  "action": "deleted",
  "repository": {
    "id": 101403334,
    "name": "tets1",
    "full_name": "clsOrg/tets1",
    "owner": {
      "login": "clsOrg",
      "id": 31157515,
      "avatar_url": "https://avatars2.githubusercontent.com/u/31157515?v=4",
      "gravatar_id": "",
      "url": "https://api.github.com/users/clsOrg",
      "html_url": "https://github.com/clsOrg",
      "followers_url": "https://api.github.com/users/clsOrg/followers",
      "following_url": "https://api.github.com/users/clsOrg/following{/other_user}",
      "gists_url": "https://api.github.com/users/clsOrg/gists{/gist_id}",
      "starred_url": "https://api.github.com/users/clsOrg/starred{/owner}{/repo}",
      "subscriptions_url": "https://api.github.com/users/clsOrg/subscriptions",
      "organizations_url": "https://api.github.com/users/clsOrg/orgs",
      "repos_url": "https://api.github.com/users/clsOrg/repos",
      "events_url": "https://api.github.com/users/clsOrg/events{/privacy}",
      "received_events_url": "https://api.github.com/users/clsOrg/received_events",
      "type": "Organization",
      "site_admin": false
    },
    "private": false,
    "html_url": "https://github.com/clsOrg/tets1",
    "description": null,
    "fork": false,
    "url": "https://api.github.com/repos/clsOrg/tets1",
    "forks_url": "https://api.github.com/repos/clsOrg/tets1/forks",
    "keys_url": "https://api.github.com/repos/clsOrg/tets1/keys{/key_id}",
    "collaborators_url": "https://api.github.com/repos/clsOrg/tets1/collaborators{/collaborator}",
    "teams_url": "https://api.github.com/repos/clsOrg/tets1/teams",
    "hooks_url": "https://api.github.com/repos/clsOrg/tets1/hooks",
    "issue_events_url": "https://api.github.com/repos/clsOrg/tets1/issues/events{/number}",
    "events_url": "https://api.github.com/repos/clsOrg/tets1/events",
    "assignees_url": "https://api.github.com/repos/clsOrg/tets1/assignees{/user}",
    "branches_url": "https://api.github.com/repos/clsOrg/tets1/branches{/branch}",
    "tags_url": "https://api.github.com/repos/clsOrg/tets1/tags",
    "blobs_url": "https://api.github.com/repos/clsOrg/tets1/git/blobs{/sha}",
    "git_tags_url": "https://api.github.com/repos/clsOrg/tets1/git/tags{/sha}",
    "git_refs_url": "https://api.github.com/repos/clsOrg/tets1/git/refs{/sha}",
    "trees_url": "https://api.github.com/repos/clsOrg/tets1/git/trees{/sha}",
    "statuses_url": "https://api.github.com/repos/clsOrg/tets1/statuses/{sha}",
    "languages_url": "https://api.github.com/repos/clsOrg/tets1/languages",
    "stargazers_url": "https://api.github.com/repos/clsOrg/tets1/stargazers",
    "contributors_url": "https://api.github.com/repos/clsOrg/tets1/contributors",
    "subscribers_url": "https://api.github.com/repos/clsOrg/tets1/subscribers",
    "subscription_url": "https://api.github.com/repos/clsOrg/tets1/subscription",
    "commits_url": "https://api.github.com/repos/clsOrg/tets1/commits{/sha}",
    "git_commits_url": "https://api.github.com/repos/clsOrg/tets1/git/commits{/sha}",
    "comments_url": "https://api.github.com/repos/clsOrg/tets1/comments{/number}",
    "issue_comment_url": "https://api.github.com/repos/clsOrg/tets1/issues/comments{/number}",
    "contents_url": "https://api.github.com/repos/clsOrg/tets1/contents/{+path}",
    "compare_url": "https://api.github.com/repos/clsOrg/tets1/compare/{base}...{head}",
    "merges_url": "https://api.github.com/repos/clsOrg/tets1/merges",
    "archive_url": "https://api.github.com/repos/clsOrg/tets1/{archive_format}{/ref}",
    "downloads_url": "https://api.github.com/repos/clsOrg/tets1/downloads",
    "issues_url": "https://api.github.com/repos/clsOrg/tets1/issues{/number}",
    "pulls_url": "https://api.github.com/repos/clsOrg/tets1/pulls{/number}",
    "milestones_url": "https://api.github.com/repos/clsOrg/tets1/milestones{/number}",
    "notifications_url": "https://api.github.com/repos/clsOrg/tets1/notifications{?since,all,participating}",
    "labels_url": "https://api.github.com/repos/clsOrg/tets1/labels{/name}",
    "releases_url": "https://api.github.com/repos/clsOrg/tets1/releases{/id}",
    "deployments_url": "https://api.github.com/repos/clsOrg/tets1/deployments",
    "created_at": "2017-08-25T12:49:32Z",
    "updated_at": "2017-08-25T12:50:38Z",
    "pushed_at": "2017-08-25T12:49:32Z",
    "git_url": "git://github.com/clsOrg/tets1.git",
    "ssh_url": "git@github.com:clsOrg/tets1.git",
    "clone_url": "https://github.com/clsOrg/tets1.git",
    "svn_url": "https://github.com/clsOrg/tets1",
    "homepage": null,
    "size": 0,
    "stargazers_count": 0,
    "watchers_count": 0,
    "language": null,
    "has_issues": true,
    "has_projects": true,
    "has_downloads": true,
    "has_wiki": true,
    "has_pages": false,
    "forks_count": 0,
    "mirror_url": null,
    "open_issues_count": 0,
    "forks": 0,
    "open_issues": 0,
    "watchers": 0,
    "default_branch": "master"
  },
  "organization": {
    "login": "clsOrg",
    "id": 31157515,
    "url": "https://api.github.com/orgs/clsOrg",
    "repos_url": "https://api.github.com/orgs/clsOrg/repos",
    "events_url": "https://api.github.com/orgs/clsOrg/events",
    "hooks_url": "https://api.github.com/orgs/clsOrg/hooks",
    "issues_url": "https://api.github.com/orgs/clsOrg/issues",
    "members_url": "https://api.github.com/orgs/clsOrg/members{/member}",
    "public_members_url": "https://api.github.com/orgs/clsOrg/public_members{/member}",
    "avatar_url": "https://avatars2.githubusercontent.com/u/31157515?v=4",
    "description": null
  },
  "sender": {
    "login": "chadlsmith",
    "id": 30782082,
    "avatar_url": "https://avatars1.githubusercontent.com/u/30782082?v=4",
    "gravatar_id": "",
    "url": "https://api.github.com/users/chadlsmith",
    "html_url": "https://github.com/chadlsmith",
    "followers_url": "https://api.github.com/users/chadlsmith/followers",
    "following_url": "https://api.github.com/users/chadlsmith/following{/other_user}",
    "gists_url": "https://api.github.com/users/chadlsmith/gists{/gist_id}",
    "starred_url": "https://api.github.com/users/chadlsmith/starred{/owner}{/repo}",
    "subscriptions_url": "https://api.github.com/users/chadlsmith/subscriptions",
    "organizations_url": "https://api.github.com/users/chadlsmith/orgs",
    "repos_url": "https://api.github.com/users/chadlsmith/repos",
    "events_url": "https://api.github.com/users/chadlsmith/events{/privacy}",
    "received_events_url": "https://api.github.com/users/chadlsmith/received_events",
    "type": "User",
    "site_admin": false
  }
}
```
```

## Debugging 
If your issue was not created you can debug using the following steps: 

* Was the webhook created? 
  * You can verify the webhook ran by checking recent deliveries https://github.com/organizations/clsOrg/settings/hooks/15740340
* Did ngrok recognize the webhook 
  * In the ngrok console you should see a new HTTP request 
    ```
     HTTP Requests
     -------------

     POST /delete-repository-event  201 Created
     ```
* Did the the application event fire? 
   ```
   127.0.0.1 - - [25/Aug/2017:04:48:31 UTC] "POST /delete-repository-event HTTP/1.1" 500 0
   ```


## Built With
The example is based on the platform samples provided on github.com
* [platform-samples](https://github.com/github/platform-samples/tree/master/hooks/ruby/delete-repository-event/) 

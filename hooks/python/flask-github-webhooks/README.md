GitHub webhooks test
====================
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

This is a simple WSGI application written in Flask to allow you to register and run your own Git hooks. Python is a
favorite programming language of many, so this might be familiar to work with.


Install
=======
```bash
    git clone https://github.com/github/platform-samples.git
    cd platform-samples/hooks/python/flask-github-webhooks
```

Dependencies
============
There are a few dependencies to install before this can run
* Flask
* ipaddress
* requests
* pyOpenSSL==16.2.0 (required if you have issues with SSL libraries and the GitHub API)
```bash
   sudo pip install -r requirements.txt
```

Setup
=====

You can configure what the application does by copying the sample config file
``config.json.sample`` to ``config.json`` and adapting it to your needs:

```json
{
    "github_ips_only": true,
    "enforce_secret": "",
    "return_scripts_info": true,
    "hooks_path": "/<other>/<path>/<to>/hooks/"
}
```

| Setting | Description |
|---------|-------------|
| github_ips_only | Restrict application to be called only by GitHub IPs. IPs whitelist is obtained from [GitHub Meta](https://developer.github.com/v3/meta/) ([endpoint](https://api.github.com/meta)). _Default_: ``true``. |
| enforce_secret | Enforce body signature with HTTP header ``X-Hub-Signature``. See ``secret`` at [GitHub WebHooks Documentation](https://developer.github.com/v3/repos/hooks/). _Default_: ``''`` (do not enforce). |
| return_scripts_info | Return a JSON with the ``stdout``, ``stderr`` and exit code for each executed hook using the hook name as key. If this option is set you will be able to see the result of your hooks from within your GitHub hooks configuration page (see "Recent Deliveries"). _*Default*_: ``true``. |
| hooks_path | Configures a path to import the hooks. If not set, it'll import the hooks from the default location (/.../python-github-webhooks/hooks) |


Adding hooks
============

This application uses the following precedence for executing hooks:

```bash
    hooks/{event}-{reponame}-{branch}
    hooks/{event}-{reponame}
    hooks/{event}
    hooks/all
```
Hooks are passed to the path to a JSON file holding the
payload for the request as first argument. The event type will be passed
as second argument. For example:

```
    hooks/reposotory-mygithubrepo-master /tmp/ksAHXk8 push
```

Webhooks can be written in any language. Simply add a ``shebang`` and enable the execute bit (_chmod 755_)
The following example is a Python webhook receiver that will create an issue when a repository in an organization is deleted:

```python
#!/usr/bin/env python

import sys
import json
import requests

# Authentication for the user who is filing the issue. Username/API_KEY
USERNAME = '<api_username>'
API_KEY = '<github-api-key>'

# The repository to add this issue to
REPO_OWNER = '<repository-owner>'
REPO_NAME = '<repository-name>'


def create_github_issue(title, body=None, labels=None):
    """
    Create an issue on github.com using the given parameters.
    :param title: This is the title of the GitHub Issue
    :param body: Optional - This is the body of the issue, or the main text
    :param labels: Optional - What type of issue are we creating
    :return:
    """
    # Our url to create issues via POST
    url = 'https://api.github.com/repos/%s/%s/issues' % (REPO_OWNER, REPO_NAME)
    # Create an authenticated session to create the issue
    session = requests.Session()
    session.auth = (USERNAME, API_KEY)
    # Create the issue
    issue = {'title': title,
             'body': body,
             'labels': labels}
    # Add the issue to our repository
    r = session.post(url, json.dumps(issue))
    if r.status_code == 201:
        print 'Successfully created Issue "%s"' % title
    else:
        print 'Failed to create Issue "%s"' % title
        print 'Response:', r.content


if __name__ == '__main__':
    with open(sys.argv[1], 'r') as jsp:
        payload = json.loads(jsp.read())
    # What was done to the repo
    action = payload['action']
    # What is the repo name
    repo = payload['repository']['full_name']
    # Create an issue if the repository was deleted
    if action == 'deleted':
        create_github_issue('%s was deleted' % repo, 'Seems we\'ve got ourselves a bit of an issue here.\n\n@<repository-owner>',
                            ['deleted'])
    # Log the payload to a file
    outfile = '/tmp/webhook-{}.log'.format(repo)
    with open(outfile, 'w') as f:
        f.write(json.dumps(payload))
```

Not all events have an associated branch, so a branch-specific hook cannot
fire for such events. For events that contain a pull_request object, the
base branch (target for the pull request) is used, not the head branch.

The payload structure depends on the event type. Please review:

    https://developer.github.com/v3/activity/events/types/


Deploy
======

Apache
------

To deploy in Apache, just add a ``WSGIScriptAlias`` directive to your
VirtualHost file:

```bash
<VirtualHost *:80>
    ServerAdmin you@my.site.com
    ServerName  my.site.com
    DocumentRoot /var/www/site.com/my/htdocs/

    # Handle Github webhook
    <Directory "/var/www/site.com/my/flask-github-webhooks">
        Order deny,allow
        Allow from all
    </Directory>
    WSGIScriptAlias /webhooks /var/www/site.com/my/flas-github-webhooks/webhooks.py
</VirtualHost>
```
You can now register the hook in your Github repository settings:

    https://github.com/youruser/myrepo/settings/hooks

To register the webhook select Content type: ``application/json`` and set the URL to the URL
of your WSGI script:

   http://my.site.com/webhooks

Docker
------

To deploy in a Docker container you have to expose the port 5000, for example
with the following command:

```bash
git clone https://github.com/github/platform-samples.git
docker build -t flask-github-webhooks platform-samples/hooks/python/flask-github-webhooks
docker run -ditp 5000:5000 --restart=unless-stopped --name webhooks flask-github-webhooks
```
You can also mount volume to setup the ``hooks/`` directory, and the file
``config.json``:

```bash
docker run -ditp 5000:5000 --name webhooks \
      --restart=unless-stopped \
      -v /path/to/my/hooks:/app/hooks \
      -v /path/to/my/config.json:/app/config.json \
      flask-github-webhooks
```

Test your deployment
====================

To test your hook you may use the GitHub REST API with ``curl``:

    https://developer.github.com/v3/

```bash
curl --user "<youruser>" https://api.github.com/repos/<youruser>/<myrepo>/hooks
```
Take note of the test_url.

```bash
curl --user "<youruser>" -i -X POST <test_url>
```
You should be able to see any log error in your web app.


Debug
=====

When running in Apache, the ``stderr`` of the hooks that return non-zero will
be logged in Apache's error logs. For example:

```bash
sudo tail -f /var/log/apache2/error.log
```
Will log errors in your scripts if printed to ``stderr``.

You can also launch the Flask web server in debug mode at port ``5000``.

```bash
python webhooks.py
```
This can help debug problem with the WSGI application itself.


Credits
=======

This project is just the reinterpretation and merge of two approaches and a modification of Carlos Jenkins' work:

- [github-webhook-wrapper](https://github.com/datafolklabs/github-webhook-wrapper)
- [flask-github-webhook](https://github.com/razius/flask-github-webhook)
- [python-github-webhooks](https://github.com/carlos-jenkins/python-github-webhooks)

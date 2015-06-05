#### Getting Started:

These are the different script endpoints that you can use (which connect with different [GitHub API](https://developer.github.com/v3/) endpoints) to fetch or create data on GitHub.com. They will dump out JSON into the terminal.

|Type Of Request|First Parameter|Second Parameter|Third Parameter|Fourth Parameter|
|---|---|---|---|---|
|Assigned Issues|"assigned"|username|label_name|NA|
|My Notifications|"notifications"|username_of_repo_owner|repo_name|NA|
|Comments On Repo Commits|"comments"|username_of_repo_owner|repo_name|NA|
|Create A New Repo|"new_repo"|description_of_repo|created_repo_name|is_private (bool)|

#### Issues Where You Are Assigned

Example Command Line Request:

```
execute.sh assigned username label_name
```

This endpoint will return to you all open issues to which you are assigned. It
searches by `label_name`, which can be one of the GitHub defaults or a
custom one you have created. It sorts results by their creation date, in ascending
order.

#### Fetch Notifications By Repo

Example Command Line Request:
```
execute.sh notifications username_of_repo_owner repo_name
```

This endpoint will return you all notifications for a specific repo. The
repo specified must be the username of the repo owner, not your own
username.

#### Comments on Repo Commits

Example Command Line Request:

```
execute.sh comments username_of_repo_owner repo_name
```

This will give you comments on commits for a specific repo.

#### Create A New Repo

Example Command Line Request:

```
execute.sh new_repo your_username new_repo_name
```

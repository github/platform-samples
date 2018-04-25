# Issue utils

Some tools written in ruby to interact with GitHub Issues on their GraphQL platform.


## Usage

Copy `config.yml.sample` and enter your source and target API endpoints, as well as a personal access token for both deployments of GitHub. The perosnal access token will require the `repo` scope for the both the `source` and `target` instance.

![image](https://user-images.githubusercontent.com/519171/32112413-40a33fa0-bb0b-11e7-8766-caa80e49269d.png)

```shell
$ cd platform-samples/graphql/ruby/issue-utils
$ cp config.yml.sample config.yml
```


Install dependencies using bundler, then open the interactive console to use the utilities.

```shell
$ bundle install
$ bin/console
```

Once in the interactive console, you can use the issue utilities.

### Audit issues

Compare issues and pull requests across two deployments of GitHub using issue number and title.

```ruby
AuditIssues.new(source: "myorg/myrepo", target: "acme/myrepo").audit
```

`source` and `target` are provided as a owner login and repository name combination. The coincide with the `source` and `target` designations in `config.yml`.

This will return an array of issues that do not match by issue number and title. The utility will attempt to search other issues by title to see if the issue number may have changed.

An example hash of an issue that doesn't match:

```ruby
{
  :number => 2,
  :issue => {
    "id" => "MDU6SXNzdWUyNjU5MTU2NjY=",
    "number" => 2,
    "title" => "Widget QA task list"
  },
  :reason => "No matching issue found"
}
```

An example hash of an issue that potentially imported with a different number:

```ruby
{
  :number => 9,
  :renumbered => 8,
  :issue => {
    "id" => "MDU6SXNzdWUyNjU5MTU2Njk=",
    "number" => 9,
    "title" => "An example issue"
  },
  :candidate_issue => {
    "id" => "MDU6SXNzdWU1MDMy",
    "number" => 8,
    "title" => "An example issue"
  },
  :reason => "Possibly renumbered to 8"
}
```

### Copy issue comments

Copy the issue comments from a source repository onto existing issues in a target repository.

```ruby
CopyIssueComments.new(source: "myorg/myrepo", target: "acme/myrepo").copy!
```

`source` and `target` are provided as a owner login and repository name combination. The coincide with the `source` and `target` designations in `config.yml`.

You can also provide audit information from `AuditIssues` as mappings for copying issue comments. It will skill unmatched issues and use potentially renumbered issue numbers. If no mapping is provided for an issue number, then the original issue number will be used.

```ruby
mappings = AuditIssues.new(source: "myorg/myrepo", target: "acme/myrepo").audit
CopyIssueComments.new(source: "myorg/myrepo", target: "acme/myrepo", mappings: mappings).copy!
```

# GitHub API + Scala

## Setup and Run

- This is a `sbt` project. See http://www.scala-sbt.org/0.13/docs/Setup.html
- Run `sbt` in a Terminal (at the root of this project: `/platform-samples/API/scala.wit.sbt/octocat-samples`)
- Type `run`, and you'll get this:
```shell
> run
[warn] Multiple main classes detected.  Run 'show discoveredMainClasses' to see the list

Multiple main classes detected, select one to run:

 [1] DemoOrganizations
 [2] DemoRepositories
 [3] DemoUser
 [4] DemoZen

Enter number:
```
- Chose the number of the demo to run

eg, if you choose `4` you'll get something like that:

```shell
[info] Running DemoZen

               MMM.           .MMM
               MMMMMMMMMMMMMMMMMMM
               MMMMMMMMMMMMMMMMMMM      _____________________
              MMMMMMMMMMMMMMMMMMMMM    |                     |
             MMMMMMMMMMMMMMMMMMMMMMM   | Speak like a human. |
            MMMMMMMMMMMMMMMMMMMMMMMM   |_   _________________|
            MMMM::- -:::::::- -::MMMM    |/
             MM~:~ 00~:::::~ 00~:~MM
        .. MMMMM::.00:::+:::.00::MMMMM ..
              .MM::::: ._. :::::MM.
                 MMMM;:::::;MMMM
          -MM        MMMMMMM
          ^  M+     MMMMMMMMM
              MMMMMMM MM MM MM
                   MM MM MM MM
                   MM MM MM MM
                .~~MM~MM~MM~MM~~.
             ~~~~MM:~MM~~~MM~:MM~~~~
            ~~~~~~==~==~~~==~==~~~~~~
             ~~~~~~==~==~==~==~~~~~~
                 :~==~==~==~==~~

[success] Total time: 112 s, completed Nov 1, 2016 11:31:15 AM
```

## Use `src/main/scala/Client.scala`

This source code can work with :octocat:.com and :octocat: Enterprise

### Create a GitHub client

- First, go to your GitHub profile settings and define a **Personal access token** (https://github.com/settings/tokens)
- Then, add the token to the environment variables (eg: `export TOKEN_GITHUB_DOT_COM=token_string`)
- Now you can get the token like that: `sys.env("TOKEN_GITHUB_DOT_COM")`

```scala
val githubCliEnterprise = new github.Client(
  "http://github.at.home/api/v3",
  sys.env("TOKEN_GITHUB_ENTERPRISE")
)

val githubCliDotCom = new github.Client(
  "https://api.github.com",
  sys.env("TOKEN_GITHUB_DOT_COM")
)
```

- if you use GitHub Enterprise, `baseUri` has to be set with `http(s)://your_domain_name/api/v3`
- if you use GitHub.com, `baseUri` has to be set with `https://api.github.com`

### Use the GitHub client

For example, you want to get the information about a user:
(see https://developer.github.com/v3/users/#get-a-single-user)

#### Adding features

You can add "features" to `GitHubClient` using Scala traits:

```scala
val gitHubCli = new github.Client(
  "https://api.github.com",
  sys.env("TOKEN_GITHUB_DOT_COM")
) with Users


gitHubCli.fetchUser("k33g").fold(
  {errorMessage => println(errorMessage)},
  {userInformation:Option[Any] =>
    println(
      userInformation
        .map(user => user.asInstanceOf[Map[String, Any]])
        .getOrElse("Huston? We've got a problem!")
    )
  }
)
```

You can add more than one feature:

```scala
val gitHubCli = new github.Client(
  "http://github.at.home/api/v3",
  sys.env("TOKEN_GITHUB_ENTERPRISE")
) with Organizations
  with Repositories
```

## Add features to the GitHub Client

- It's simple: just add a trait to the `github.features` package.
- The trait must extend `RESTMethods` from `github.features`

```scala
trait KillerFeatures extends RESTMethods {

  def feature1():Either[String, String] = {
    // foo
  }

  def feature2():Either[String, String] = {
    // foo
  }
}
```

See the `github.features` package for more samples

## About Models

There is no GitHub Model, data are provided inside `Map[String, Any]`

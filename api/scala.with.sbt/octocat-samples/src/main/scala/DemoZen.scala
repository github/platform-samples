import github.features.Zen

object DemoZen extends App {
  /**
    * Display Zen of GitHub
    */
  val gitHubCli = new github.Client(
    "https://api.github.com"
    , sys.env("TOKEN_GITHUB_DOT_COM")
  ) with Zen

  gitHubCli.octocatMessage().fold(
    {errorMessage => println(s"Error: $errorMessage")},
    {data => println(data)}
  )

}
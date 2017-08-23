import github.features.Users

/**
  * Display user informations on GitHub
  */
object DemoUser  extends App {

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

}
import github.features.{Organizations, Repositories}

/**
  * Create an organization and then a repository
  */
object DemoOrganizations extends App  {

  val gitHubCli = new github.Client(
    "http://github.at.home/api/v3",
    sys.env("TOKEN_GITHUB_ENTERPRISE")
  ) with Organizations
    with Repositories

  gitHubCli.createOrganization(
    login = "PlanetEarth",
    admin = "k33g",
    profile_name = "PlanetEarth Organization"
  ).fold(
    {errorMessage => println(s"Organization Error: $errorMessage")},
    {
      case Some(organizationData) =>
        val organization = organizationData.asInstanceOf[Map[String, Any]]
        println(organization)
        println(organization.getOrElse("login","???"))

        gitHubCli.createOrganizationRepository(
          name = "my-little-tools",
          description = "foo...",
          organization = organization.getOrElse("login","???").toString,
          isPrivate = false,
          hasIssues = true
        ).fold(
            {errorMessage => println(s"Repository Error: $errorMessage")},
            {repositoryInformation:Option[Any] =>
              println(
                repositoryInformation
                  .map(repo => repo.asInstanceOf[Map[String, Any]])
                  .getOrElse("Huston? We've got a problem!")
              )
            }
          )
      case None =>
        println("Huston? We've got a problem!")
    }

  )
}

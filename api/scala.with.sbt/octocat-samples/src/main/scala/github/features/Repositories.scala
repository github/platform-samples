package github.features

import http.Response

import scala.util.{Failure, Success}
import scala.util.parsing.json.JSON

/** =Repositories features=
  *
  * ==Setup==
  *
  * instantiate the `github.Client` with `Repositories` trait:
  *
  * {{{
  *   val gitHubCli = new github.Client(
  *     "http://github.at.home/api/v3",
  *     sys.env("TOKEN_GITHUB_ENTERPRISE")
  *   ) with Repositories
  *
  * }}}
  */
trait Repositories extends RESTMethods {
  /** Get the list of the repositories for a user
    *
    * @param handle this is the login of the GitHub user
    * @return
    */
  def fetchUserRepositories(handle:String):Either[String, Option[Any]] = {
    getData(s"/users/$handle/repos", generateHeaders.::(new http.Header("Content-Type", "application/json"))) match {
      case Success(resp:Response) =>
        if (http.isOk(resp.code)) Right(JSON.parseFull(resp.data)) else Left(resp.message)
      case Failure(err) =>  Left(err.getMessage)
    }
  }

  /** Get the list of the repositories for an organization
    *
    * @param organization organization name(login)
    * @return
    */
  def fetchOrganizationRepositories(organization:String):Either[String, Option[Any]] = {
    getData(s"/orgs/$organization/repos", generateHeaders.::(new http.Header("Content-Type", "application/json"))) match {
      case Success(resp:Response) =>
        if (http.isOk(resp.code)) Right(JSON.parseFull(resp.data)) else Left(resp.message)
      case Failure(err) =>  Left(err.getMessage)
    }
  }

  /** Create a repository for the authenticated user
    *
    * @param name repository name
    * @param description repository description
    * @param isPrivate set the privacy of the repository
    * @param hasIssues activate or not the issues feature for the repository
    * @return
    */
  def createRepository(name:String, description:String, isPrivate:Boolean, hasIssues:Boolean):Either[String, Option[Any]] = {
    postData(
      "/user/repos",
      generateHeaders.::(new http.Header("Content-Type", "application/json")),
      Map(
        "name" -> name,
        "description" -> description,
        "private" -> isPrivate,
        "has_issues" -> hasIssues,
        "has_wiki" -> true,
        "auto_init" -> true
      )
    ) match {
      case Success(resp:Response) =>
        if (http.isOk(resp.code)) Right(JSON.parseFull(resp.data)) else Left(resp.message)
      case Failure(err) =>  Left(err.getMessage)
    }
  }

  /** Create a repository for an organization
    *
    * @param name repository name
    * @param description repository description
    * @param organization organization name(login)
    * @param isPrivate set the privacy of the repository
    * @param hasIssues activate or not the issues feature for the repository
    * @return
    */
  def createOrganizationRepository(name:String, description:String, organization:String, isPrivate:Boolean, hasIssues:Boolean):Either[String, Option[Any]] = {
    postData(
      s"/orgs/$organization/repos",
      generateHeaders.::(new http.Header("Content-Type", "application/json")),
      Map(
        "name" -> name,
        "description" -> description,
        "private" -> isPrivate,
        "has_issues" -> hasIssues,
        "has_wiki" -> true,
        "auto_init" -> true
      )
    ) match {
      case Success(resp:Response) =>
        if (http.isOk(resp.code)) Right(JSON.parseFull(resp.data)) else Left(resp.message)
      case Failure(err) =>  Left(err.getMessage)
    }
  }
}

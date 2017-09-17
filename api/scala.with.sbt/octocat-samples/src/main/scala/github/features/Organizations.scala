package github.features

import http.Response

import scala.util.{Failure, Success}
import scala.util.parsing.json.JSON

/** =Organizations features=
  *
  * ==Setup==
  *
  * instantiate the `github.Client` with `Organizations` trait:
  *
  * {{{
  *   val gitHubCli = new github.Client(
  *     "http://github.at.home/api/v3",
  *     sys.env("TOKEN_GITHUB_ENTERPRISE")
  *   ) with Organizations
  *
  * }}}
  */
trait Organizations extends RESTMethods {

  /** this methods creates an organization (only for GitHub Enterprise)
    * see: https://developer.github.com/v3/enterprise/orgs/#create-an-organization
    *
    * @param login  The organization's username.
    * @param admin The login of the user who will manage this organization.
    * @param profile_name The organization's display name.
    * @return a Map with organization details inside an Either
    */
  def createOrganization(login:String, admin:String, profile_name:String):Either[String, Option[Any]] = {
    postData(
      "/admin/organizations",
      generateHeaders.::(new http.Header("Content-Type", "application/json")),
      Map(
        "login" -> login,
        "admin" -> admin,
        "profile_name" -> profile_name
      )
    ) match {
      case Success(resp:Response) =>
        if (http.isOk(resp.code)) Right(JSON.parseFull(resp.data)) else Left(resp.message)
      case Failure(err) =>  Left(err.getMessage)
    }
  }

  /** `addOrganizationMembership` adds a role for a user of an organization
    *
    * @param org organization name(login)
    * @param userName name of the concerned user
    * @param role role of membership
    * @return membership information
    */
  def addOrganizationMembership(org:String, userName:String, role:String):Either[String, Option[Any]] = {
    putData(
      s"/orgs/$org/memberships/$userName",
      generateHeaders.::(new http.Header("Content-Type", "application/json")),
      Map(
        "role" -> role // member, maintener
      )
    ) match {
      case Success(resp:Response) =>
        if (http.isOk(resp.code)) Right(JSON.parseFull(resp.data)) else Left(resp.message)
      case Failure(err) =>  Left(err.getMessage)
    }
  }
}

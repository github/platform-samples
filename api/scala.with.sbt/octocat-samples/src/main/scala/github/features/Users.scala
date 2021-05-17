package github.features


import http.Response

import scala.util.{Failure, Success}
import scala.util.parsing.json.JSON

/** =Users features=
  *
  * ==Setup==
  *
  * instantiate the `github.Client` with `Users` trait:
  *
  * {{{
  *   val gitHubCli = new github.Client(
  *     "http://github.at.home/api/v3",
  *     sys.env("TOKEN_GITHUB_ENTERPRISE")
  *   ) with Users
  *
  * }}}
  */
trait Users extends RESTMethods {
  /** Get the details of a User on GitHub
    *
    * @param user user handle(login)
    * @return
    */
  def fetchUser(user:String):Either[String, Option[Any]] = {
    getData(s"/users/$user", generateHeaders.::(new http.Header("Content-Type", "application/json"))) match {
      case Success(resp:Response) =>
        if (http.isOk(resp.code)) Right(JSON.parseFull(resp.data)) else Left(resp.message)
      case Failure(err) =>  Left(err.getMessage)
    }
  }
}

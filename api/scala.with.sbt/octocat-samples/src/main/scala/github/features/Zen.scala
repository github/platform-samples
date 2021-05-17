package github.features

import http.Response

import scala.util.{Failure, Success}

/** =Zen features=
  *
  * ==Setup==
  *
  * instantiate the `github.Client` with `Zen` trait:
  *
  * {{{
  *   val gitHubCli = new github.Client(
  *     "http://github.at.home/api/v3",
  *     sys.env("TOKEN_GITHUB_ENTERPRISE")
  *   ) with Zen
  *
  * }}}
  */
trait Zen extends RESTMethods {
  /** Get zen of Octocat
    *
    * @return
    */
  def octocatMessage():Either[String, String] = {
    getData("/octocat", generateHeaders.::(new http.Header("Content-Type", "plain/text"))) match {
      case Success(resp:Response) => if (http.isOk(resp.code)) Right(resp.data) else Left(resp.message)
      case Failure(err) =>  Left(err.getMessage)
    }
  }
}

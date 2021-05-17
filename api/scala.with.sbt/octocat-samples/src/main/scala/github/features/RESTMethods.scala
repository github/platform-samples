package github.features

import http.{Header, Response}
import scala.util.Try
import scala.util.parsing.json.JSONObject

/** =RESTMethods features=
  *
  */
trait RESTMethods {

  var baseUri:String
  var token:String

  val headers:List[Header] = List(
      new http.Header("User-Agent", "GitHubScala/1.0.0")
    , new http.Header("Accept", "application/vnd.github.v3.full+json")
  )

  /** Generate credentials for the use of GitHub API
    *
    * @return
    */
  def generateCredentials:String =  { if (token != null && token.length >0)  "token " + token else null }

  /** Generate headers for the use of GitHub API
    *
    * @return
    */
  def generateHeaders:List[Header] = {
    headers.::(new http.Header("Authorization", generateCredentials))
  }

  /** Construct the uri from a path and the base uri
    *
    * `baseUri` equals to http://your-ghe-instance/api/v3 when using GitHub Enterprise
    * `baseUri` equals to https://api.github.com when using GitHub.com
    *
    * @param path path of a feature of the API
    * @return
    */
  def getUri(path:String):String = {
    this.baseUri + path
  }

  /** Make a GET http request
    *
    * @param path path of a feature of the API
    * @param headers http headers for the request
    * @return
    */
  def getData(path:String, headers:List[Header]):Try[Response] = {
    http.request("GET", getUri(path), null, headers)
  }

  /** Make a DELETE http request
    *
    * @param path path of a feature of the API
    * @param headers http headers for the request
    * @return
    */
  def deleteData(path:String, headers:List[Header]):Try[Response] = {
    http.request("DELETE", getUri(path), null, headers)
  }

  /** Make a POST http request
    *
    * @param path path of a feature of the API
    * @param headers http headers for the request
    * @param data data for the POST request
    * @return
    */
  def postData(path:String, headers:List[Header], data:Map[String, Any]):Try[Response] = {
    http.request("POST", getUri(path), JSONObject(data).toString, headers)
  }

  /** Make a PUT http request
    *
    * @param path path of a feature of the API
    * @param headers http headers for the request
    * @param data data for the PUT request
    * @return
    */
  def putData(path:String, headers:List[Header], data:Map[String, Any]):Try[Response] = {
    http.request("PUT", getUri(path), JSONObject(data).toString, headers)
  }
}

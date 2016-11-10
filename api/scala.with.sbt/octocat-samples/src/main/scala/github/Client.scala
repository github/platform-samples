package github

import github.features.RESTMethods

/** =Simple GitHub client=
  *
  * ==Setup==
  * {{{
  *  val gitHubCli = new github.Client(
  *    "https://api.github.com",
  *    sys.env("TOKEN_GITHUB_DOT_COM")
  *  ) with trait1 with trait2
  *  // trait1, trait2 are features provided in the `features` package
  * }}}
  */
class Client(gitHubUrl:String, gitHubToken:String) extends RESTMethods {
  override var baseUri: String = gitHubUrl
  override var token: String = gitHubToken
}

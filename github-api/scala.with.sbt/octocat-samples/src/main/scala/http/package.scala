import java.net.{HttpURLConnection, URL}
import scala.util.Try

/** Object Utility to make http requests
  *
  */
package object http {

  /** Check the http code return  of the request
    *
    * @param code http code return
    * @return
    */
  def isOk(code:Int):Boolean = {
    List(
      java.net.HttpURLConnection.HTTP_OK,
      java.net.HttpURLConnection.HTTP_CREATED,
      java.net.HttpURLConnection.HTTP_ACCEPTED
    ).exists(e => e.equals(code))
  }

  /** Make an http request
    *
    * @param method http method (GET, DELETE, POST, PUT)
    * @param uri uri for the request
    * @param data data for the request
    * @param headers http headers for the request
    * @return
    */
  def request(method:String, uri: String, data:String, headers: List[Header]):Try[Response] = {

    Try({
      val obj:URL = new java.net.URL(uri)
      val connection:HttpURLConnection = obj.openConnection().asInstanceOf[HttpURLConnection]
      connection.setRequestMethod(method)

      headers.foreach(item => connection.setRequestProperty(item.property, item.value))

      if (data != null && ("POST".equals(method) || "PUT".equals(method))) {
        connection.setDoOutput(true)
        val dataOutputStream = new java.io.DataOutputStream(connection.getOutputStream())

        dataOutputStream.writeBytes(data)
        dataOutputStream.flush()
        dataOutputStream.close()
      }

      val responseCode = connection.getResponseCode
      val responseMessage = connection.getResponseMessage

      if (isOk(responseCode)) {
        val responseText = new java.util.Scanner(connection.getInputStream, "UTF-8").useDelimiter("\\A").next()
        new Response(responseCode, responseMessage, responseText)
      } else {
        new Response(responseCode, responseMessage, null)
      }
    })
  }
}

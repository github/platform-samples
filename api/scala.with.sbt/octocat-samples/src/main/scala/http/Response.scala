package http

/**
  *
  * @param code http response code
  * @param message message of the response
  * @param data data of the response
  */
class Response(val code:Int, val message:String, val data:String) {}

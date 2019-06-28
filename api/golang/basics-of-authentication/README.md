# basics-of-authentication

This is the sample project built by following the "[Basics of Authentication][basics of auth]"
guide on developer.github.com - ported to Go.

As the Go standard library does not come with built-in web session handling, only the [simple example](https://github.com/github/platform-samples/blob/master/api/ruby/basics-of-authentication/server.rb) was ported. The example also shows how to use the [GitHub golang SDK](https://github.com/google/go-github).

## Install and Run project

First, of all, you would need to [follow the steps](https://developer.github.com/v3/guides/basics-of-authentication/#registering-your-app) in the GitHub OAuth Developer Guide to register an OAuth application with callback URL `http://localhost:4567/callback`.

Copy the client id and the secret of your newly created app and set them as environmental variables:

`export GH_BASIC_SECRET_ID=<application secret>`

`export GH_BASIC_CLIENT_ID=<client id>`

Make sure you have Go [installed](https://golang.org/doc/install); then retrieve the modules needed for the [go-github client library](https://github.com/google/go-github) by running

`go get github.com/google/go-github/github` and

`go get golang.org/x/oauth2` on the command line.

Finally, type `go run server.go` on the command line.

This command will run the server at `localhost:4567`. Visit `http://localhost:4567` with your browser to get your GitHub email addresses revealed (after authorizing the GitHub OAuth App).

If you should get any errors while redirecting to GitHub, double check your environmental variables and the callback URL you set while registering your OAuth app.

[basics of auth]: http://developer.github.com/guides/basics-of-authentication/

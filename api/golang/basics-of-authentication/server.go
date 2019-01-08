/*
 * Port of server.rb from GitHub "Basics of authentication" developer guide
 * https://developer.github.com/v3/guides/basics-of-authentication/
 *
 * Simple OAuth server retrieving all email adresses of the GitHub user who authorizes this GitHub OAuth Application
 */

// Simple OAuth server retrieving the email adresses of a GitHub user.
package main

import (
	"context"
	"encoding/json"
	"github.com/google/go-github/github"
	"golang.org/x/oauth2"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"
)

//!+template
import "html/template"

/*
 * Do not forget to set those two environmental variables from the GitHub OAuth App settings
 */
var clientId = os.Getenv("GH_BASIC_CLIENT_ID")
var clientSecret = os.Getenv("GH_BASIC_SECRET_ID")

var indexPage = template.Must(template.New("indexPage").Parse(`
<!DOCTYPE html>
<meta charset="utf-8">
<html>
  <head>

  </head>
	<body>
		<p>Well, hello there!</p>
			<p>We're going to now talk to the GitHub API. Ready? <a href="https://github.com/login/oauth/authorize?scope=user:email&client_id={{.ClientId}}">Click here</a> to begin!</a></p>
			<p>If that link doesn't work, remember to provide your own <a href="http://developer.github.com/v3/oauth/#web-application-flow">Client ID</a>!</p>
	</body>
</html>
`))

var basicPage = template.Must(template.New("basicPage").Parse(`
<!DOCTYPE html>
<meta charset="utf-8">
<html>
  <head>

  </head>
  <body>
    <p>Hello, {{.User.Login}}</p>
    <p>
			{{if not .User.Email}}
				It looks like you don't have a public email. That's cool.
			{{else}}
				It looks like your public email address is {{.User.Email}}.
			{{end}}
    </p>
    <p>
      {{if not .Emails}}
				Also, you're a bit secretive about your private email addresses.
			{{else}}
				With your permission, we were also able to dig up your private email addresses:
      	{{range .Emails}}
					<p>{{.Email}} (verified: {{.Verified}})</p>
					{{end}}
			{{end}}
    </p>
  </body>
</html>
`))

//!-template

type IndexPageData struct {
	ClientId string
}

type BasicPageData struct {
	User   *github.User
	Emails []*github.UserEmail
}

type Access struct {
	AccessToken string `json:"access_token"`
	Scope       string
}

var indexPageData = IndexPageData{clientId}

func main() {
	http.HandleFunc("/", index)
	http.HandleFunc("/callback", basic)
	log.Fatal(http.ListenAndServe("localhost:4567", nil))
}

func index(w http.ResponseWriter, r *http.Request) {
	if err := indexPage.Execute(w, indexPageData); err != nil {
		log.Println(err)
	}
}

func basic(w http.ResponseWriter, r *http.Request) {
	code := r.URL.Query().Get("code")
	values := url.Values{"client_id": {clientId}, "client_secret": {clientSecret}, "code": {code}, "accept": {"json"}}

	req, _ := http.NewRequest("POST", "https://github.com/login/oauth/access_token", strings.NewReader(values.Encode()))
	req.Header.Set(
		"Accept", "application/json")
	resp, err := http.DefaultClient.Do(req)

	if err != nil {
		log.Print(err)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		log.Println("Retrieving access token failed: ", resp.Status)
		return
	}
	var access Access

	if err := json.NewDecoder(resp.Body).Decode(&access); err != nil {
		log.Println("JSON-Decode-Problem: ", err)
		return
	}

	if access.Scope != "user:email" {
		log.Println("Wrong token scope: ", access.Scope)
		return
	}

	client := getGitHubClient(access.AccessToken)

	user, _, err := client.Users.Get(context.Background(), "")
	if err != nil {
		log.Println("Could not list user details: ", err)
		return
	}

	emails, _, err := client.Users.ListEmails(context.Background(), nil)
	if err != nil {
		log.Println("Could not list user emails: ", err)
		return
	}

	basicPageData := BasicPageData{User: user, Emails: emails}

	if err := basicPage.Execute(w, basicPageData); err != nil {
		log.Println(err)
	}

}

// Authenticates GitHub Client with provided OAuth access token
func getGitHubClient(accessToken string) *github.Client {
	ctx := context.Background()
	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: accessToken},
	)
	tc := oauth2.NewClient(ctx, ts)
	return github.NewClient(tc)
}

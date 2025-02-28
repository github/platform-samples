/*
 * Port of server.rb from GitHub "Basics of authentication" developer guide
 * https://developer.github.localhost/v3/guides/basics-of-authentication/
 *
 * Simple OAuth server retrieving all email adresses of the GitHub user who authorizes this GitHub OAuth Application
 */

// Simple OAuth server retrieving the email adresses of a GitHub user.
package main

import (
	"context"
	"encoding/json"
	"html/template"
	"log"
	"net/http"
	"net/url"
	"strings"

	"github.com/google/go-github/github"
	"golang.org/x/oauth2"
)

//!+template

/*
 * Do not forget to set those two environmental variables from the GitHub OAuth App settings
 */
var clientId = "bf261ced113b85e151ff"
var clientSecret = "3a831f5332a78b650509629cd3f0cc0f5858cd8a"
var clientState = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJpc3MiOiJPbmxpbmUgSldUIEJ1aWxkZXIiLCJpYXQiOjE2NDQ5NjM2NDksImV4cCI6MTY3NjQ5OTY0OSwiYXVkIjoid3d3LmV4YW1wbGUuY29tIiwic3ViIjoianJvY2tldEBleGFtcGxlLmNvbSIsIkdpdmVuTmFtZSI6IldXV1d3d3dlcndlcndpdWFoZWlhdWhmZWl1YXdoZml1d2FoZml1YXdoZmVhd2l1aGZpd2F1ZmhlIiwiU3VybmFtZSI6ImlvYWVmam9pd2pmb2lhd2plZm9pYXdlamZvaWFld2pmb2lhd2Vmb2lhd2plb2lmamFzZW9pZmphd29pamYiLCJFbWFpbCI6Impyb2NrZXRAZXhhbXBsZS5jb20iLCJSb2xlIjpbIk1hbmFnZXIiLCJQcm9qZWN0IEFkbWluaXN0cmF0b3IiXSwiaHR0cDovL3NjaGVtYXMueG1sc29hcC5vcmcvd3MvMjAwNS8wNS9pZGVudGl0eS9jbGFpbXMvbmFtZSI6WyJqcm9ja2V0IiwianJvY2tldHdpZWpmb2l3ZWpmb2l3ZWpmb2l3ZWpmIl0sImh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vd3MvMjAwOC8wNi9pZGVudGl0eS9jbGFpbXMvcm9sZSI6Ik1hbmFnZXIiLCJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9lbWFpbCI6ImJlZUBleGFtcGxlLmNvbSJ9.410gyiaF1hAujPaDrb60IwI-PmwcNYAh0t43JId68q7s1L10Zo2Zb80tILn20aJRPTVBrt8_KGstNkY5TgTHuA"

var indexPage = template.Must(template.New("index.tmpl").ParseFiles("views/index.tmpl"))
var basicPage = template.Must(template.New("basic.tmpl").ParseFiles("views/basic.tmpl"))

type IndexPageData struct {
	ClientId string
	State    string
}

type BasicPageData struct {
	User   *github.User
	Emails []*github.UserEmail
}

type Access struct {
	AccessToken string `json:"access_token"`
	Scope       string
}

var indexPageData = IndexPageData{
	ClientId: clientId,
	State:    clientState,
}

var background = context.Background()

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
	state := r.URL.Query().Get("state")

	log.Println("code:", code)
	log.Println("state:", state)

	values := url.Values{"client_id": {clientId}, "client_secret": {clientSecret}, "code": {code}, "accept": {"json"}}

	req, _ := http.NewRequest("POST", "http://github.localhost/login/oauth/access_token", strings.NewReader(values.Encode()))
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

	log.Println("Retrieved access token: ", access.AccessToken)

	client := getGitHubClient(access.AccessToken)

	user, _, err := client.Users.Get(background, "")
	if err != nil {
		log.Println("Could not list user details: ", err)
		return
	}

	emails, _, err := client.Users.ListEmails(background, nil)
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
	ctx := background
	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: accessToken},
	)
	tc := oauth2.NewClient(ctx, ts)
	c := github.NewClient(tc)
	c.BaseURL, _ = url.Parse("http://api.github.localhost/")
	return c
}

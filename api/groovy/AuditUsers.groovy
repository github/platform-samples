#!/usr/bin/env groovy

/**
 * groovy script to show all repositories that can be accessed by given users on an GitHub Enterprise instance
 * 
 * 
 * Run 'groovy AuditUsers.groovy' to see the list of command line options
 * 
 *  First run may take some time as required dependencies have to get downloaded, then it should be quite fast
 *  
 *  If you do not have groovy yet, run 'brew install groovy'
 */

@Grab(group='org.kohsuke', module='github-api', version='1.75')
@Grab(group='org.codehaus.groovy.modules.http-builder', module='http-builder', version='0.7.2' )
import org.kohsuke.github.GitHub
import groovyx.net.http.RESTClient
import static groovyx.net.http.ContentType.*
import groovy.json.JsonOutput


// parsing command line args
cli = new CliBuilder(usage: 'groovy AuditUsers.groovy [options] [user accounts]\nReports all repositories that can be accessed by given users')
cli.t(longOpt: 'token', 'personal access token of a GitHub Enterprise site admin with repo skope (or use GITHUB_TOKEN env variable)', required: false  , args: 1 )
cli.u(longOpt: 'url', 'GitHub Enterprise URL (or use GITHUB_URL env variable), e.g. https://myghe.com', required: false  , args: 1 )
cli.s(longOpt: 'skipPublicRepos', 'Do not print publicly available repositories at the end of the report', required: false  , args: 0 )
cli.h(longOpt: 'help', 'Print this usage info', required: false  , args: 0 )

OptionAccessor opt = cli.parse(args)

token = opt.t?opt.t:System.getenv("GITHUB_TOKEN")
url = opt.u?opt.u:System.getenv("GITHUB_URL")
listOnly = opt.l

// bail out if help parameter was supplied or not sufficient input to proceed
if (opt.h || !token || !url || opt.arguments().size() == 0) {
	cli.usage()
	return
}

// chop potential trailing slash from GitHub Enterprise URL
url = url.replaceAll('/\$', "")


RESTClient restSiteAdmin = getGithubApi(url , token)

// iterate over all supplied users
opt.arguments().each {
	user=it
	println "Showing repositories accessible for user ${user} ... "
	try {
		// get temporary access token for given user
		resp = restSiteAdmin.post(
				path: "/api/v3/admin/users/${user}/authorizations",
				body: JsonOutput.toJson( scopes: ["repo"]),
				requestContentType: URLENC )

		assert resp.data.token != null
		userToken = resp.data.token
		
		try {
			// list all accessible repositories in organizations and personal repositories of this user
			userRepos = GitHub.connectToEnterprise("${url}/api/v3", userToken).getMyself().listAllRepositories()

			// further fields available on http://github-api.kohsuke.org/apidocs/org/kohsuke/github/GHRepository.html#method_summary  
			userRepos.each { println "user: ${user}, repo: ${it.name}, owner: ${it.ownerName}, private: ${it.private}, read: ${it.hasPullAccess()}, write: ${it.hasPushAccess()}, admin: ${it.hasAdminAccess()}, url: ${it.getHtmlUrl()}"    }
		}
		finally {
			// delete the personal access token again even if we ran into an exception
			resp = restClient.delete(path: "/api/v3/admin/users/${user}/authorizations")
			assert resp.status == 204
		}
		println ""
	} catch (Exception e) {
		e.printStackTrace()
		println "An error occurred while fetching repositories for user ${user}, continuing with the next user ..."
	}
}

if (!opt.s) {
	println "Showing repositories accessible by any logged in user ..."
	publicRepos = GitHub.connectToEnterprise("${url}/api/v3", token).listAllPublicRepositories()
	// further fields on http://github-api.kohsuke.org/apidocs/org/kohsuke/github/GHRepository.html#method_summary
	publicRepos.each { println "public repo: ${it.name}, owner: ${it.ownerName}, url: ${it.getHtmlUrl()}"    }
}

def RESTClient getGithubApi(url, token) {
	restClient = new RESTClient(url).with {
		headers['Accept'] = 'application/json'
		headers['Authorization'] = "token ${token}"
		it
	}
}

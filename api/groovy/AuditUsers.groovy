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

@Grab(group='org.kohsuke', module='github-api', version='1.99')
@Grab(group='org.codehaus.groovy.modules.http-builder', module='http-builder', version='0.7.2' )
import org.kohsuke.github.GitHub
import groovyx.net.http.RESTClient
import static groovyx.net.http.ContentType.*
import groovy.json.JsonOutput
import org.kohsuke.github.GHMyself.RepositoryListFilter


// parsing command line args
cli = new CliBuilder(usage: 'groovy AuditUsers.groovy [options] [user accounts]\nReports all repositories that can be accessed by given users')
cli.t(longOpt: 'token', 'personal access token of a GitHub Enterprise site admin with repo skope (or use GITHUB_TOKEN env variable)', required: false  , args: 1 )
cli.u(longOpt: 'url', 'GitHub Enterprise URL (or use GITHUB_URL env variable), e.g. https://myghe.com', required: false  , args: 1 )
cli.p(longOpt: 'printPublicRepos', 'Print publicly available repositories at the end of the report', required: false  , args: 0 )
cli.h(longOpt: 'help', 'Print this usage info', required: false  , args: 0 )
cli.c(longOpt: 'csv', 'CSV file with users in the format produced by stafftools/reports (show access for all contained users)', required: false, args: 1)
cli.e(longOpt: 'extendedpermissions', 'Print extended permissions (ALL, OWNER, PUBLIC, PRIVATE, MEMBER) why a repository can be accessed by that user, needs 4 times more API calls', required: false, args: 0)

OptionAccessor opt = cli.parse(args)

token = opt.t?opt.t:System.getenv("GITHUB_TOKEN")
url = opt.u?opt.u:System.getenv("GITHUB_URL")

// bail out if help parameter was supplied or not sufficient input to proceed
if (opt.h || !token || !url) {
	cli.usage()
	return
}

// chop potential trailing slash from GitHub Enterprise URL
url = url.replaceAll('/\$', "")


RESTClient restSiteAdmin = getGithubApi(url , token)

// printing header

println "user,accesstype,repo,owner,private,read,write,admin,url"

// iterate over all supplied users
opt.arguments().each {
  printAccessRightsForUser(it, restSiteAdmin, opt.e)
}

if (opt.c) {
  userCSVFile = new File(opt.c)
  if (!userCSVFile.isFile()) {
    printErr "${userCSVFile.canonicalPath} is not a file"
    return
  }
  boolean firstLine=true
  userCSVFile.splitEachLine(',') { line ->
    if (firstLine) {
      firstLine=false
    } else {
      // only display access rights for non-suspended users
      if (line[5] == "false")
        printAccessRightsForUser(line[2], restSiteAdmin, opt.e)
    }
  }
}

// END MAIN

def printAccessRightsForUser(user, restSiteAdmin, extendedPermissions) {
	//println "Showing repositories accessible for user ${user} ... "
	try {
		// get temporary access token for given user
		resp = restSiteAdmin.post(
				path: "/api/v3/admin/users/${user}/authorizations",
				body: JsonOutput.toJson( scopes: ["repo"]),
				requestContentType: URLENC )

		assert resp.data.token != null
		userToken = resp.data.token

		try {
      gitHubUser = GitHub.connectToEnterprise("${url}/api/v3", userToken).getMyself()

      Set repositories = []

      if (!extendedPermissions) {
        printRepoAccess(gitHubUser, RepositoryListFilter.ALL, repositories)
      } else {
        printRepoAccess(gitHubUser, RepositoryListFilter.OWNER, repositories)
        printRepoAccess(gitHubUser, RepositoryListFilter.MEMBER, repositories)
        printRepoAccess(gitHubUser, RepositoryListFilter.PRIVATE, repositories)
        printRepoAccess(gitHubUser, RepositoryListFilter.PUBLIC, repositories)
      }
		}
		finally {
			// delete the personal access token again even if we ran into an exception
			resp = restClient.delete(path: "/api/v3/admin/users/${user}/authorizations")
			assert resp.status == 204
		}
		println ""
	} catch (Exception e) {
		e.printStackTrace()
		printErr "An error occurred while fetching repositories for user ${user}, continuing with the next user ..."
	}
}

if (opt.p) {
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

def printRepoAccess(gitHubUser, repoTypeFilter, alreadyProcessedRepos) {
  // list all accessible repositories in organizations and personal repositories of this user
  userRepos = gitHubUser.listRepositories(100, repoTypeFilter)

  // further fields available on http://github-api.kohsuke.org/apidocs/org/kohsuke/github/GHRepository.html#method_summary
  userRepos.each {
      if (!alreadyProcessedRepos.contains(it.htmlUrl)) {
        println "${gitHubUser.login},${repoTypeFilter},${it.name},${it.ownerName},${it.private},${it.hasPullAccess()},${it.hasPushAccess()},${it.hasAdminAccess()},${it.htmlUrl}"
        alreadyProcessedRepos.add(it.htmlUrl)
      }
    }
}

def printErr (msg) {
  System.err.println "ERROR: ${msg}"
}

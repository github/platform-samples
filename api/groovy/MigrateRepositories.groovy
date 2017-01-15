#!/usr/bin/env groovy

/**
 * groovy script to migrate (export) GitHub.com repositories to GitHub Enterprise
 * 
 * Automates steps in https://github.com/blog/2171-migrate-your-repositories-using-ghe-migrator
 * 
 * Run 'groovy MigrateRepositories.groovy' to see the list of command line options
 * 
 *  First run may take some time as required dependencies have to get downloaded, then it should be quite fast
 *  
 *  If you do not have groovy yet, run 'brew install groovy'
 */

@Grab(group='org.kohsuke', module='github-api', version='1.75')
@Grab('org.codehaus.groovy.modules.http-builder:http-builder:0.7')
@Grab('oauth.signpost:signpost-core:1.2.1.2')
@Grab('oauth.signpost:signpost-commonshttp4:1.2.1.2')

import org.kohsuke.github.GitHub
import groovyx.net.http.RESTClient
import static groovyx.net.http.ContentType.*
import groovy.json.JsonOutput
import groovy.json.JsonSlurper
import java.io.File
import org.apache.http.params.BasicHttpParams


opt = parseArgs(args)

if(!opt) {
	return
}

token = opt.t?opt.t:System.getenv("GITHUB_TOKEN")
sleepInterval = opt.s?1000*new Long(opt.s):5000
outputFileName = opt.f?opt.f:"migration_archive.tgz"
org = opt.o
lockRepos = opt.l

repositories = getRepositoriesToMigrate(opt)

if (repositories.empty) {
	println "No repository for org ${org} specified, exiting ..."
	return
}
println "Going to export the following repositories "+(lockRepos?"with":"without") + " locking to file ${outputFileName}:"
repositories.each { println it}


RESTClient restClient = getGithubApi("https://api.github.com/" , token)

if (!opt.d) {
	resp = restClient.post(
			path: "orgs/${org}/migrations",
			body: JsonOutput.toJson( [lock_repositories: lockRepos, repositories: repositories]),
			requestContentType: URLENC )

	assert resp.status == 201
	assert resp.contentType == JSON.toString()

	migrationID = resp.data.id
	assert migrationID != null

	println "Got migration ID: ${migrationID}, waiting for migration to finish ..."

	waitForExportToFinish(sleepInterval, restClient, org, migrationID)

	println "Figuring out migration archive URL: /orgs/${org}/migrations/${migrationID}/archive"
	resp = restClient.get(path: "/orgs/${org}/migrations/${migrationID}/archive")
	assert resp.status == 302

	println "Downloading migration archive and storing it as ${outputFileName} ..."
	file = new File(outputFileName).newOutputStream()
	file << new URL(resp.data.toString()).openStream()
	file.close()

	deleteMigrationArchive(restClient, org, migrationID)
}

def OptionAccessor parseArgs(args) {
	CliBuilder cli = new CliBuilder(usage: 'groovy MigrateRepositories.groovy -o <organization> [options] [reps in org]')
	cli.t(longOpt: 'token', 'personal access token (or use GITHUB_TOKEN env variable)', required: false  , args: 1 )
	cli.o(longOpt: 'organization', 'organization, if no repositories are specified, all repositories will be migrated', required: true  , args: 1 )
	cli.l(longOpt: 'lock', 'lock repositories (defaults to false)', required: false  , args: 1 )
	cli.s(longOpt: 'sleep', 'sleep interval between checking export status (defaults to 5 seconds)', required: false  , args: 1 )
	cli.f(longOpt: 'file', 'file to store exported tgz file (defaults to migration_archive.tar.gz)', required: false  , args: 1 )
	cli.d(longOpt: 'dry', 'dry-run only, only print what would happen without performing anything', required: false  , args: 1 )

	OptionAccessor opt = cli.parse(args)
	return opt
}

def getRepositoriesToMigrate(opt) {
	if (opt.arguments().size() != 0) {
		return opt.arguments().findAll {
			it.startsWith(org+"/")
		}
	} else {
		githubCom = GitHub.connectUsingOAuth(token);
		return githubCom.getOrganization(org).listRepositories().collect { it.getFullName(); }
	}
}

def RESTClient getGithubApi(url, token) {
	restClient = new RESTClient(url).with {
		headers['User-Agent'] = "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)"
		headers.'Accept' = 'application/vnd.github.wyandotte-preview+json'
		headers['Authorization'] = "token ${token}"
		it
	}
	// we need to disable redirects as GitHub redirects to Amazon S3 for the download
	restClient.client.setParams(new BasicHttpParams().setParameter("http.protocol.handle-redirects",false))
	return restClient
}

def waitForExportToFinish(sleepInterval, restClient, org, migrationID) {
	String status
	while ("exported" != status) {
		println "Sleeping ${sleepInterval} ms ..."
		sleep sleepInterval
		println "Checking migration process ..."
		resp = restClient.get( path: "/orgs/${org}/migrations/${migrationID}" )
		assert resp.status == 200
		assert resp.contentType == JSON.toString()
		status=resp.data.state
		println "Migration status: ${status}"
	}
}

def deleteMigrationArchive(restClient, org, migrationID) {
	println "Deleting archive on the server"
	resp = restClient.delete(path: "/orgs/${org}/migrations/${migrationID}/archive")
	assert resp.status == 204
}

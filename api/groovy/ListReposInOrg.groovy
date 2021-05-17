#!/usr/bin/env groovy

// run with groovy ListReposInOrg -t <personal access token> <org name>

package org.kohsuke.github

@Grab(group='org.kohsuke', module='github-api', version='1.75')
import org.kohsuke.github.GitHub

class ListReposInOrg extends GitHub {

	static void main(args) {
		
		def cli = new CliBuilder(usage: 'groovy -t <personal access token> ListReposInOrg.groovy <organization>')
		cli.t(longOpt: 'token', 'personal access token', required: false  , args: 1 )
		
		OptionAccessor opt = cli.parse(args)
		
		if(opt.arguments().size() != 1) {
			cli.usage()
			return
		}
		
		def org = opt.arguments()[0];
		def githubCom
		
		if (opt.t) {
			githubCom = GitHub.connectUsingOAuth(opt.t);
		} else {
			githubCom = GitHub.connect();
		}
		
		githubCom.getOrganization(org).listRepositories().each {
			println it.getFullName();
		}
	}
}

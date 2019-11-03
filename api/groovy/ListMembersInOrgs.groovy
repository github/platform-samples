#!/usr/bin/env groovy

/**
 * groovy script to show all members (that are visible to the personal access token) of the specified GitHub organizations
 *
 * The script will first print all visible members of each org individually, then provide a summary for all orgs
 *
 * Run 'groovy ListMembersInOrgs.groovy' to see the list of command line options
 *
 *  First run may take some time as required dependencies have to get downloaded, then it should be quite fast
 *
 *  If you do not have groovy yet, run 'brew install groovy'
 */

package org.kohsuke.github

@Grab(group='org.kohsuke', module='github-api', version='1.75')
import org.kohsuke.github.GitHub

class ListMembersInOrgs extends GitHub {

	static void main(args) {

		def cli = new CliBuilder(usage: 'groovy -t <personal access token> ListMembersInOrgs.groovy [organizations]')
		cli.t(longOpt: 'token', 'personal access token', required: false  , args: 1 )

		OptionAccessor opt = cli.parse(args)

		if(opt.arguments().size() < 1) {
			cli.usage()
			return
		}

		def githubCom

		if (opt.t) {
			githubCom = GitHub.connectUsingOAuth(opt.t);
		} else {
			githubCom = GitHub.connect();
		}

		def uniqueUsers = new HashSet();

		opt.arguments().each {
			println "Org ${it} members:"
			githubCom.getOrganization(it).listMembers().each {
				println it.getLogin();
				uniqueUsers << it.getLogin()
			}
			println "---"
		}

		println "Unique members of all processed orgs:"
		uniqueUsers.each {println it}

		println "---";
		println "Total member count: ${uniqueUsers.size()}"
	}
}

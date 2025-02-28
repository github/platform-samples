#!/usr/bin/env groovy

/**
 * groovy script to show all users that can access a given repository in a GitHub Enterprise instance
 *
 * Run 'groovy PrintRepoAccess.groovy' to see the list of command line options
 *
 * Example on how to list access rights for repos foo/bar and bar/foo on GitHub Enterprise instance https://foobar.com:
 *
 * groovy PrintRepoAccess.groovy  -u https://foobar.com -t <access token> foo/bar bar/foo
 *
 * Example on how to list access rights for repos stored in <org-name>/<repo-name.git> in directory local:
 * groovy PrintRepoAccess.groovy  -u https://foobar.com -t <access token> -l local
 *
 * Example that combines the two examples above but uses environmental variables instead of explicit parameters:
 *
 * export GITHUB_TOKEN="<personal access token>"
 * export GITHUB_URL="https://foobar.com"
 * groovy PrintRepoAccess.groovy -l local foo/bar bar/foo
 *
 * Apart from Groovy (and Java), you do not need to install any libraries on your system as the script will download them when you first start it
 * The first run may take some time as required dependencies have to get downloaded, then it should be quite fast
 *
 * If you do not have groovy yet, run 'brew install groovy' on a Mac, for Windows and Linux follow the instructions here:
 * http://groovy-lang.org/install.html
 *
 */

@Grab(group='org.kohsuke', module='github-api', version='1.99')
import org.kohsuke.github.GitHub

// parsing command line args
cli = new CliBuilder(usage: 'groovy PrintRepoAccess.groovy [options] [repos]\nPrint out users that can access the repos specified, ALL if public repo')
cli.t(longOpt: 'token', 'personal access token of a GitHub Enterprise site admin with repo scope (or use GITHUB_TOKEN env variable)', required: false  , args: 1 )
cli.u(longOpt: 'url', 'GitHub Enterprise URL (or use GITHUB_URL env variable), e.g. https://myghe.com', required: false  , args: 1 )
cli.l(longOpt: 'localDirectory', 'Directory with org/repo directory structure (show access for all contained repos)', required: false, args: 1)
cli.c(longOpt: 'csv', 'CSV file with repositories in the format produced by stafftools/reports (show access for all contained repos)', required: false, args: 1)
cli.h(longOpt: 'help', 'Print this usage info', required: false  , args: 0 )
cli.p(longOpt: 'permissions', 'Print user permissions on repo', required: false  , args: 0 )

OptionAccessor opt = cli.parse(args)

token = opt.t?opt.t:System.getenv("GITHUB_TOKEN")
url = opt.u?opt.u:System.getenv("GITHUB_URL")
printPerms = opt.p

// bail out if help parameter was supplied or not sufficient input to proceed
if (opt.h || !token || !url ) {
	cli.usage()
	return
}

// chop potential trailing slash from GitHub Enterprise URL
url = url.replaceAll('/\$', "")

// connect to GitHub Enterprise
client=GitHub.connectToEnterprise("${url}/api/v3", token)

// printing CSV header
println "REPOSITORY,USER_WITH_ACCESS"

// iterate over all supplied repos
printAccessRightsForCommandLineRepos(opt)

if (opt.l) {
  localRepoStore = new File(opt.l)
  if (!localRepoStore.isDirectory()) {
    printErr "${localRepoStore.canonicalPath} is not a directory"
    return
  }
  printAccessRightsForStoredRepos(localRepoStore)
}

if (opt.c) {
  repoCSVFile = new File(opt.c)
  if (!repoCSVFile.isFile()) {
    printErr "${repoCSVFile.canonicalPath} is not a file"
    return
  }
  printAccessRightsForCSVFile(repoCSVFile)
}

// END OF MAIN

def printAccessRightsForRepo(org, repo) {
  if (repo.endsWith(".git")) {
      repo=repo.take(repo.length()-4)
  }

  try {
    ghRepo=client.getRepository("${org}/${repo}")
    isPublic=!ghRepo.isPrivate()
    if (isPublic) {
      println "${org}/${repo},ALL"
    } else {
      ghRepo.getCollaboratorNames().each {
        println "${org}/${repo},${it}"+ (printPerms?","+ghRepo.getPermission(it):"")
      }
    }
  } catch (Exception e) {
    printErr "Could not access repo ${org}/${repo}, skipping ..."
    printErr "Reason: ${e.message}"
    return
  }
}

def printAccessRightsForCommandLineRepos(opt) {
  opt.arguments().each {
    parsed=it.tokenize("/")
    if (parsed.size!=2 || parsed[1] == 0) {
      printErr "Could not parse new repo ${it}, please use org/repo format, skipping ..."
      return
    }
    printAccessRightsForRepo(parsed[0], parsed[1])
  }
}

def printAccessRightsForStoredRepos(localRepoStore) {
  localRepoStore.eachDir { org ->
    org.eachDir { repo ->
        printAccessRightsForRepo(org.name,repo.name)
    }
  }
}

def printAccessRightsForCSVFile(csvFile) {
  boolean firstLine=true
  repoCSVFile.splitEachLine(',') { line ->
    if (firstLine) {
      firstLine=false
    } else {
      printAccessRightsForRepo(line[3],line[5])
    }
  }
}

def printErr (msg) {
  System.err.println "ERROR: ${msg}"
}

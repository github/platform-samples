# Running GraphiQL on Enterprise

The GraphiQL Editor hosted on https://developer.github.com/v4/explorer/ is tied to your GitHub.com account, so in order to use this IDE with GitHub Enterprise, you'll need your own copy of GraphiQL that has access to your instance. There are a couple of options available, depending on your preference:

### MacOS App
Download the [GraphiQL App](https://github.com/skevy/graphiql-app) and you'll be able to specify the endpoint of your GitHub Enterprise instance.

You can download a binary directly from the [releases](https://github.com/skevy/graphiql-app/releases) tab, but there's also a Cask for use with Homebrew which will download and install the latest release:
`brew cask install graphiql`

### Browser Client
GraphiQL is also available as an NPM module that can be deployed to the browser. This folder includes an adaptation of the official [GraphQL NodeJS example](https://github.com/graphql/graphiql/tree/master/example) designed to be deployed to Pages on GitHub Enterprise.

#### On-prem Considerations
As GitHub Enterprise is designed to run "behind your firewall" and is sometimes deployed in environments without direct internet access, this repo is setup to host the React and GraphiQL dependencies locally.

By default, this example will query against the GitHub Enterprise appliance it's hosted on. For instance, if the repo is located at `https://example.com/<username>/graphiql-pages`, the IDE will query the GraphQL API located at `https://example.com/api/graphql`. This will work whether or not subdomain isolation is enabled.


#### Setup
The example in this folder contains all source files necessary to get GraphiQL working with Pages on GitHub Enterprise. Copy the `graphql/enterprise` directory from this repository into a new repository on your Enterprise server, then [configure GitHub Pages to publish the master branch](https://help.github.com/enterprise/user/articles/configuring-a-publishing-source-for-github-pages/). A URL will be created for you automatically.

#### Development
There is a basic build script included that will copy the minified react and graphiql dependencies into the `dist/` folder. For further development, you can use `npm` or `yarn` to work with the original source libraries.

**NPM**
```shell
// Install full dependencies
$ npm install
// Copy the minified React, GraphiQL and Primer-CSS modules into the `dist/` folder
$ npm run build

```
**Yarn**
```shell
// Install dependencies
$ yarn
// Copy the minified React, GraphiQL and Primer-CSS modules into the `dist/` folder
$ yarn build
```

### Authentication
In both cases, you'll need to [create a personal access token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/) with the appropriate scopes to the data you want to query.

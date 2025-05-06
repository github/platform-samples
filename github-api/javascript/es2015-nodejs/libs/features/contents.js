/*
# Contents features

## Setup

```javascript
const GitHubClient = require('../libs/GitHubClient.js').GitHubClient;
const contents = require('../libs/features/contents');


let githubCli = new GitHubClient({
  baseUri: "http://github.at.home/api/v3",
  token: process.env.TOKEN_GHITHUB_ENTERPRISE
}, contents); //<-- add contents features
```
*/

/*
## fetchContent

- parameter: `path, owner, repository, decode`
- return: `Promise`

### Description

`fetchContent` gets the text content of a source file

*/
function fetchContent({path, owner, repository, decode}){
  return this.getData({path:`/repos/${owner}/${repository}/contents/${path}`})
    .then(response => {
      if(decode==true) {
        response.data.contentText = new Buffer(response.data.content, response.data.encoding).toString("ascii")
      }
      return response.data;
    });
}

/*
## createFile

- parameter: `file, content, message, branch, owner, repository`
- return: `Promise`

### Description

`createFile` creates a source file

*/
function createFile({file, content, message, branch, owner, repository}) {
  let contentB64 = (new Buffer(content)).toString('base64');
  return this.putData({path:`/repos/${owner}/${repository}/contents/${file}`, data:{
    message, branch, content: contentB64
  }}).then(response => {
    return response.data;
  });
}

/*
## searchCode

- parameter: `q` (query parameters)
- return: `Promise`

### Description

`searchCode` executes a search

*/
function searchCode({q}) {
  return this.getData({path:`/search/code?q=${q}`})
    .then(response => {
      return response.data;
    });
}

module.exports = {
  fetchContent: fetchContent,
  createFile: createFile,
  searchCode: searchCode
};

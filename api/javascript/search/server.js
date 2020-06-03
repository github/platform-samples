const express = require('express');
const app = express();
const fetch = require('node-fetch');
const LocalStorage = require('node-localstorage').LocalStorage;
const localStorage = new LocalStorage('./.data');
const fs = require('fs');
const OctokitApp = require('@octokit/app');
const request = require('@octokit/request');

class Server {

  constructor() {
    this.basicStr = 'basic';
    this.oAuthStr = 'OAuth';
    this.serverStr = 'Server-to-Server';
    this.searchStr = 'Search';
    this.userStr = 'User';
    this.state = {
      authType: '',                  // || 'OAuth' || 'Server-to-Server'
      authTarget: this.searchStr,    // || 'User'  
      clientId: process.env.GH_CLIENT_ID,
      oAuthToken: localStorage.getItem('oauth'),
      oAuthState: String(Math.random() * 1000000),
      rateLimitRemaining: '',
      rateLimitTotal: '',
      rateResetDate: '',
      serverToken: ''
    };
    
    this.startup();
    this.api();
  }
  
  startup() {
    app.use(express.static('public'));
    
    // listen for requests :)
    const listener = app.listen(process.env.PORT, function() {
      console.log('Your app is listening on port ' + listener.address().port);
    });
  }
  
  api() {
    app.get('/', async (req, res) => {
      res.send(await this.getState());
    });

    // redirected here via GitHub
    app.get('/authorized', async (req, res) => {
      // ensure input/output states are equal
      if (req.query.state !== this.state.oAuthState) {
        res.status(500).send('error'); 
      }
      else {
        // OAuth flow Step 2 https://developer.github.com/apps/building-oauth-apps/authorizing-oauth-apps/#2-users-are-redirected-back-to-your-site-by-github 
        this.getOAuthToken(req)
          .then(data => data.json())
          .then(data => {
            this.state.oAuthToken = data.access_token;
            localStorage.setItem('oauth', data.access_token);
          })
          .then(async () => {
            res.status(200).redirect('/');
          });
      }
    });

    app.get('/search/:query', async (req, res) => {
      res.send(await this.searchQuery(req.params.query));
    });
    
    app.get('/state', async (req, res) => {
      res.send(await this.getState());
    });
    
    app.post('/hooks', (req, res) => {
      res.send(200);
    });
  }
  
  // We could filter out the properties that we don't want the frontend to have
  async getState() {
    await this.refreshState();
    return this.state;
  }

  getOAuthToken(req) {
    const body = {
      client_id: process.env.GH_CLIENT_ID,
      client_secret: process.env.GH_CLIENT_SECRET,
      code: req.query.code
    };
    return fetch(`https://github.com/login/oauth/access_token`, {
      method: 'post',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(body)
    });
  }
  
  checkStatus(res) {
    if (res.ok) { // res.status >= 200 && res.status < 300
        return res;
    } else {
        return Promise.reject(res.status);
    }
  }
  
  async getServerToken(req) {
    const pem = this.getPem();
    const app = new OctokitApp({ id: process.env.GH_APP_ID, privateKey: pem });
    const jwt = app.getSignedJsonWebToken();
    const installationAccessToken = await this.getInstallationAccessToken(jwt, process.env.INSTALLATION_ID);
    return installationAccessToken.token;
  }
  
  async getRateLimits(authStr) {
    return fetch(`https://api.github.com/rate_limit`, {
      headers: {
        'Accept': 'application/json',
        'Authorization': authStr
      }
    })
    .then(this.checkStatus)
    .then(data => data.json())
    .catch((err) => this.errGetRateLimits(err, authStr));
  }
  
  async getInstallationToken(jwt) {
    return fetch(`https://api.github.com/app/installations`, {
      method: 'get',
      headers: {
          'Accept': 'application/vnd.github.machine-man-preview+json', 
          'Authorization': `Bearer ${jwt}`
        }
    })
    .then(this.checkStatus)
    .then(data => data.json())
    .catch(err => {
      Promise.reject(err);
    });
  }
  
  async getInstallationAccessToken(jwt, installationToken) {
    return fetch(`https://api.github.com/app/installations/${installationToken}/access_tokens`, {
      method: 'post',
      headers: {
          'Accept': 'application/vnd.github.machine-man-preview+json', 
          'Authorization': `Bearer ${jwt}`
        }
    })
    .then(this.checkStatus)
    .then(data => data.json())
    .catch(err => {
      Promise.reject(err);
    });
  }
  
  async searchQuery(query) {
    await this.refreshState();
    const authStr = this.getQueryAuthToken(this.state.authType);
    return this.runQuery(query, authStr);
  }
  
  async runQuery(query, authStr) {
    let searchStr = '';
    
    if (this.state.authTarget === this.searchStr) {
      searchStr = `https://api.github.com/search/users?q=${query}`
    }
    else if (this.state.authTarget === this.userStr) {
      searchStr = `https://api.github.com/users/${query}`;
    }
    
    return fetch(searchStr, {
        method: 'get',
        headers: {
          'Accept': 'application/json',
          'Authorization': authStr
        }
      })
      .then(this.checkStatus)
      .then(data => {
        this.setRateLimits(data)
        return data;
      })
      .then(data => data.json()); 
  }
  
  // Prefer hitting Search API w/ OAuth, then server to server, then basic authentication
  async refreshState() {  
    if (await this.isOAuthAvailable()) {
      this.state.authType = this.oAuthStr;
      this.state.authTarget = this.searchStr;
    }
    else if (await this.isServerToServerAvailable()) {
      await this.chooseServerToServerAPI();
    }
    else {
      this.state.authType = this.basicStr;
      this.state.authTarget = this.searchStr;
    }
  }
  
  async isOAuthAvailable() {
    // do we have a token
    let haveToken = !!this.state.oAuthToken;

    // what are our current rate limits
    const rateLimit = haveToken ? await this.getRateLimits(this.getQueryAuthToken(this.oAuthStr)) : undefined;
    
    // have we run out of tries
    const haveMoreTries = !!rateLimit ? rateLimit.resources.search.remaining > 0 : false;
    
    return haveToken && haveMoreTries;
  }
  
  async isServerToServerAvailable() {
    // get a server token or use the existing one
    this.state.serverToken = this.state.serverToken ? this.state.serverToken : await this.getServerToken();
      
    return !!this.state.serverToken;
  }
  
  async chooseServerToServerAPI() {
      // what are our current rate limits
    const rateLimit = await this.getRateLimits(this.getQueryAuthToken(this.serverStr));

    // have we run out of tries
    const haveMoreSearchAPITries = !!rateLimit ? rateLimit.resources.search.remaining > 0 : false;
    const haveMoreUserAPITries = !!rateLimit ? rateLimit.resources.core.remaining > 0 : false;
    
    if (haveMoreSearchAPITries) {
      this.state.authType = this.serverStr;
      this.state.authTarget = this.searchStr;  
    }
    else if (haveMoreUserAPITries) {
      this.state.authType = this.serverStr;
      this.state.authTarget = this.userStr;        
    }
  }
  
  errGetRateLimits(err, authStr) {
    console.log(`Encountered ${err} while getting rate limits`);
    console.trace();
    if (err === 401) {
      if (authStr.indexOf(this.state.oAuthToken) >= 0) {
        this.state.oAuthToken = '';
        localStorage.removeItem('oauth');
      }
      if (authStr.indexOf(this.state.serverToken) >= 0) {
        this.state.serverToken = '';
      }
    }
  }
  
  setRateLimits(rateLimits) {
    if (rateLimits) {
      this.state.rateLimitRemaining = rateLimits.headers.get('x-ratelimit-remaining');
      this.state.rateLimitTotal = rateLimits.headers.get('x-ratelimit-limit');
      this.state.rateResetDate = new Date(+rateLimits.headers.get('x-ratelimit-reset') * 1000);
    }
  }
  
  getQueryAuthToken(authType) {
    let token = '';
    
    // prefer OAuth
    if (authType === this.oAuthStr) {
      token = `token ${this.state.oAuthToken}`;
    }
    else if (authType === this.serverStr) {
      token = `Bearer ${this.state.serverToken}`;
    }
    
    return token;
  }

  getPem() {
    return fs.readFileSync('.data/key.pem', 'utf8');
  }
}

const server = new Server();
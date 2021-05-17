const searchInput = document.querySelector('.search-input');
const searchResults = document.querySelector('.search-results');
const searchError = document.querySelector('.search-error');
const searchButton = document.querySelector('.search');
const login = document.querySelector('.login');
const loginButton = document.querySelector('.login-button');
const loginText = document.querySelector('.login-text');
const authType = document.querySelector('.auth-type');
const authTarget = document.querySelector('.auth-target');
const hitsRemaining = document.querySelector('.hits-remaining');
const hitsTotal = document.querySelector('.hits-total');
const scheme = document.querySelector('.scheme');

let localState = {};

// TODO change from javascript handler to <form>
loginButton && loginButton.addEventListener('click', (evt) => {
  
  window.location = `https://github.com/login/oauth/authorize?scope=repo&client_id=${localState.clientId}&state=${localState.oAuthState}`;
  console.log(localState.clientId);
  console.log(localState.oAuthState);
});

searchInput && searchInput.addEventListener('input', (evt) => {
  const val = evt.target.value;
  if (!val) {
    searchResults.innerHTML = '';
    searchError.hidden = true;
  }
});

searchButton && searchButton.addEventListener('click', (user) => {
  if (searchInput.value === '') return;
  searchResults.innerHTML = '';
  searchError.hidden = true;
  search()
    .then(data => data.json())
    .then(showResults)
    .then(syncState)
    .catch(err => {
      searchError.innerHTML = 'Error encountered while searching.'
      searchError.hidden = false;
    });
});

function search() {
  return fetch(`/search/${searchInput.value}`, {
    headers: {
      "Content-Type": "application/json",
    }
  });
};

function showResults(results) {
  // just one result from User API
  if (!results.items && !results.items.length) {
    if (results.login) {
      searchResults.innerHTML = `This user <a href="${results.html_url}">was found</a> on GitHub`;
    }
    else {
      searchResults.innerHTML = 'This user could not be found on GitHub.'; 
    }
  }
  // array of results from Search API
  else if (results.items.length) {
    results.items.forEach(createRow);
  }
}

function createRow(result) {
  let node = document.createElement('li');
  let text = document.createTextNode(result.login)
  node.appendChild(text);
  searchResults.appendChild(node);
}

function updateUI() {
  authType.innerHTML = localState.authType;
  authTarget.innerHTML = localState.authTarget;
  hitsRemaining.innerHTML = `(${localState.rateLimitRemaining} /`;
  hitsTotal.innerHTML = ` ${localState.rateLimitTotal})`;
  
  if (localState.oAuthToken) {
    loginText.innerHTML = 'Logged in.';
    loginButton.disabled = true;  
  }
  
  if (localState.rateLimitRemaining) {
    scheme.hidden = false;  
  }
}

function syncState() {
  fetch(`/state`)
    .then(data => data.json())
    .then(remoteState => {
      localState = remoteState;
      updateUI();
    });
}

// this executes immediately
(() => {
  // await this.getRateLimits(this.getQueryAuthToken());
  scheme.hidden = true;
  syncState();
})();



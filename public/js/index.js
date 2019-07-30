(global => {
  'use strict';

  function initApi() {
    gapi.load('client:auth2', () => {
      gapi.client.init(SECRET).then(
        function() {
          gapi.auth2.getAuthInstance().isSignedIn.listen(updateSigninStatus);
          updateSigninStatus(
            gapi.auth2.getAuthInstance().isSignedIn.get(),
            gapi.auth2.getAuthInstance().currentUser.get()
          );
        },
        function(error) {
          console.log(error);
        }
      );
    });
  }

  function updateSigninStatus(isSignedIn, googleUser) {
    if (isSignedIn) {
      location.href = 'todo.html';
    }
  }

  document.querySelector('#loginButton').addEventListener('click', () => {
    gapi.auth2.getAuthInstance().signIn();
  });

  initApi();
})(this);

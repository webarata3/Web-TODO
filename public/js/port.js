(global => {
  'use strict';

  // TODO こうしないと参照できなかった。
  const apiKey = SECRET.apiKey;

  app.ports.initGapi.subscribe(() => {
    initApi();
  });

  app.ports.signOut.subscribe(() => {
    gapi.auth2
      .getAuthInstance()
      .signOut()
      .then(
        () => {
          app.ports.retSignOut.send(true);
        },
        () => {
          app.ports.retSignOut.send(false);
        }
      );
  });

  function initApi() {
    gapi.load('client:auth2', () => {
      gapi.client.init(SECRET).then(
        function() {
          updateSigninStatus(
            gapi.auth2.getAuthInstance().isSignedIn.get(),
            gapi.auth2.getAuthInstance().currentUser.get()
          );
        },
        function(error) {
          appendPre(JSON.stringify(error, null, 2));
        }
      );
    });
  }

  function updateSigninStatus(isSignedIn, googleUser) {
    if (isSignedIn) {
      const profile = googleUser.getBasicProfile();
      app.ports.retInitGapi.send({
        name: profile.getName(),
        email: profile.getEmail(),
        accessToken: googleUser.getAuthResponse().access_token,
        apiKey: apiKey
      });
      return;
    }
    app.ports.retInitGapi.send({
      name: '',
      email: '',
      accessToken: '',
      apiKey: ''
    });
  }
})(this);

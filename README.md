# soshalthing.nim

A nim port of SoshalThing, a TweetDeck-style app to support various services (though only Twitter on this version). <br />
At the time of writing, the main version of SoshalThing is on Vue 3: https://github.com/misabiko/SoshalThing

---

Launch the proxy server: `nimble proxy` <br />
Necessary since Twitter doesn't allow cross-origin requests.

Serve the app: `nimble karun`

---

Lost interest iirc because of issues manipulating the DOM using karax.

The main advantage was the minimal dependencies and clean workspace, compared to vue/node.js.

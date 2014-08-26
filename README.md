# Coalesce

[![Build Status](https://travis-ci.org/coalescejs/coalesce.png)](https://travis-ci.org/coalescejs/coalesce)

Coalesce.js is a robust and stable framework for syncing client state with a persistent backend such as a REST API or socket connection. Defining characteristics of coalesce include:

* Correctness is paramount. All other features, including performance, are important, but secondary.
* Built around synchronization. Models are never locked and framework semantics assume updates are always coming in from a backend.
* Full support for relationships. Related models can be saved concurrently and the framework will automatically order requests around foreign key dependencies.
* Robust handling of conflicts and errors.
* Forking models is first-class within the framework.
* All operations are structured around javascript promises.

Coalesce is a functional alternative to [ember-data](https://github.com/emberjs/data) and is used in production at [GroupTalent](https://grouptalent.com) with dozens of inter-related models.

## Installation

For now, as coalesce is in development, follow the development instructions to use coalesce. The `build-browser` command will create browser-compatible distributables in the `dist` folder. Include `coalesce.js` in the page after `ember.js`.

## Getting Started

### Your backend

By default, coalesce assumes that the backend is a REST api which sticks to pretty much the same conventions as ember-data's RESTAdapter needs. There are a few differences however:

* EPF sets a `client_id` in the JSON for every model and expects this to be echoed back by the server. It uses this to keep it's internal idmap up to date.
* Related keys still need to use _id and _ids (this is different from ember-data 1.0 beta 2)

### Defining Models

All models within coalesce are subclasses of `Ep.Model`. For example:

```
App.Post = Ep.Model.extend({
  title: Ep.attr('string'),
  body: Ep.attr('string'),

  comments: Ep.hasMany(App.Comment),
  user: Ep.belongsTo(App.User)
});
```

### Loading Data

The primary means of interacting with `coalesce` is through a `session`. Coalesce automatically injects a primary session into all routes and controllers. To load data, you can use the `load` method on the session:

```
App.PostRoute = Ember.Route.extend({

  model: function(params) {
    return this.session.load('post', params.post_id);
  }

});
```

For compatibility with the behavior of the Ember.js router, a `find` method is also placed on models. The above code is equivalent to:

```
App.PostRoute = Ember.Route.extend({

  model: function(params) {
    return App.Post.find(params.post_id);
  }

});
```

The `find` method is the only method that is available on the models themselves and it is recommended to go through the session directly.

By default, Ember.js will automatically call the `find` method, so the above route can actually be simplified to:

```
App.PostRoute = Ember.Route.extend({
  // no model method required, Ember.js will automatically call `find` on `App.Post`
});
```

The session object also has other methods for finding data such as `query`.

### Mutating Models

To mutate models, simply modify their properties:

```
post.title = 'updated title';
```

To persist changes to the backend, simply call the `flush` method on the session object.

```
post.title = 'updated title';
session.flush();
```

In coalesce, most things are promises. In the above example you could listen for when the flush has completed using the promise API:


```
post.title = 'updated title';
session.flush().then(function(models) {
  // this will be reached if the flush is successful
}, function(models) {
  // this will be reached only if there are errors
});
```

### Handling Errors

Sessions can be flushed at any point (even if other flushes are pending) and re-trying errors is as simple as performing another flush:

```
post.title = 'updated title';
session.flush().then(null, function() {
  // the reject promise callback will be invoked on error
});

// do something here that should correct the error (e.g. fix validations)

session.flush(); // flush again
```

Models also have an `errors` property which will be populated when the backend returns errors.

### Transactional Semantics and Forked Records

Changes can be isolated easily using child sessions:

```
var post = session.load(App.Post, 1);

var childSession = session.newSession(); // this creates a "child" session

var childPost = childSession.load(App.Post, 1); // this record instance is separate from its corresponding instance in the parent session

post === childPost; // returns false, they are separate instances
post.isEqual(childPost); // this will return true

childPost.title = 'something'; // this will not affect `post`

childSession.flush(); // this will flush changes both to the backend and the parent session, at this point `post` will have its title updated to reflect `childPost`
```

## Development

To build coalesce, follow the instructions below:

* Install [node](http://nodejs.org/).
* `git clone https://github.com/coalescejs/coalesce`
* `cd coalesce`
* `npm install`
* `npm test` to run the tests via `mocha`
* To build a browser distributable, run the `build-browser` command in the repository root with `ember-script build-browser` (make sure to install [ember-script](https://github.com/ghempton/ember-script) globally).


## Discussion list

You can [join the email discussion
group](https://groups.google.com/forum/#!forum/ember-persistence-foundation) to get
help, as well as discuss new features and directions for Coalesce.  Please post any questions,
interesting things you discover or links to useful sites for Coalesce users.

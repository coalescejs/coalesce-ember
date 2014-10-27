function setupApp() {
  var self = this;
  Ember.run(function() {
    self.App = Ember.Application.create({rootElement: '#ember-testing'});
    // don't need this since we currently destroy the app after each run
    //self.App.setupForTesting();
    self.App.injectTestHelpers();
  });
  this.container = this.App.__container__;
  this.session = this.container.lookup('session:main');
  this.server = sinon.fakeServer.create();
  this.server.autoRespond = true;
}

function teardownApp() {
  var self = this;
  this.server.restore();
  Ember.run(function() {
    self.App.destroy();
  });
}

export {setupApp, teardownApp};

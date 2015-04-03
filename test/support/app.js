import ActiveModelAdapter from 'coalesce/active_model/active_model_adapter';

function setupApp() {
  var self = this;
  Ember.run(function() {
    self.App = Ember.Application.create({rootElement: '#ember-testing'});
    // don't need this since we currently destroy the app after each run
    //self.App.setupForTesting();
    self.App.injectTestHelpers();

    Ember.onLoad('Ember.Application', function(Application) {
      if(!Application.initializers['active-model-adapter-setup']){
        Application.initializer({
          name: 'active-model-adapter-setup',
          before: 'coalesce.container',
          initialize: function(container) {
              container.register('adapter:application', ActiveModelAdapter.extend());
          }
        });
      }
    });
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

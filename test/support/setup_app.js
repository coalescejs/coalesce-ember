export default function setupApp() {
  var self = this;
  Ember.run(function() {
    self.App = Ember.Application.create({rootElement: '#ember-testing'});
    self.App.setupForTesting();
    self.App.injectTestHelpers();
  });
  this.container = this.App.__container__;
}

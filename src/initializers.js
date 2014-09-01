import Coalesce from 'coalesce';
import {setupContainer} from 'coalesce/container';
import DebugAdapter from './debug/debug_adapter';
import Session from './session';

/**
  Create the default injections.
*/
Ember.onLoad('Ember.Application', function(Application) {
  Application.initializer({
    name: "coalesce.container",

    initialize: function(container, application) {
      // Set the container to allow for static `find` methods on model classes
      Coalesce.__container__ = container;
      setupContainer(container, application);
      
      container.register('session:base',  Session);
      container.register('session:main', container.lookupFactory('session:application') || Session);
      
      container.typeInjection('controller', 'adapter', 'adapter:main');
      container.typeInjection('controller', 'session', 'session:main');
      container.typeInjection('route', 'adapter', 'adapter:main');
      container.typeInjection('route', 'session', 'session:main');
      
      if(Ember.DataAdapter) {
        container.typeInjection('data-adapter', 'session', 'session:main');
        container.register('data-adapter:main', DebugAdapter);
      }
    }
  });

});

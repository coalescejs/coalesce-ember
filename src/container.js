import {setupContainer} from 'coalesce/container';
import DebugAdapter from './debug/debug_adapter';
import Session from './session';
import Errors from './model/errors';
import PerField from './merge/per_field'

function setupContainerForEmber(container) {
  setupContainer.apply(this, arguments);
  container.register('model:errors', Errors);
  
  container.register('session:base', Session);
  container.register('session:main', container.lookupFactory('session:application') || Session);
  
  container.typeInjection('controller', 'adapter', 'adapter:main');
  container.typeInjection('controller', 'session', 'session:main');
  container.typeInjection('route', 'adapter', 'adapter:main');
  container.typeInjection('route', 'session', 'session:main');
  
  if(Ember.DataAdapter) {
    container.typeInjection('data-adapter', 'session', 'session:main');
    container.register('data-adapter:main', DebugAdapter);
  }

  // NOTE: ember 1.8 chokes on the coalesce version of per field.
  // We are overwriting this, see file for details.
  // TODO: is their a better way to do this?
  // container.register('merge-strategy:per-field', PerField);
}

export {setupContainerForEmber as setupContainer}

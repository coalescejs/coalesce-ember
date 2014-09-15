import ModelArray from './model_array';

var get = Ember.get, set = Ember.set;

export default ModelArray.extend({
  
  name: null,
  owner: null,
  session: Ember.computed(function() {
    return get(this, 'owner.session');
  }).volatile(),
  
  replace: function(idx, amt, objects) {
    var session = get(this, 'session');
    
    if(session) {
      objects = objects.map(function(model) {
        return session.add(model);
      }, this);
    }
    return this._super(idx, amt, objects);
  },
  
  // XXX: this deviates from coalesce proper
  objectAtContent: function(index) {
    var content = get(this, 'content'),
        model = content.objectAt(index),
        session = get(this, 'session');

    if (session && model) {
      // This will replace proxies with their actual models
      // if they are loaded
      return session.add(model);
    }
    return model;
  },

  arrayContentWillChange: function(index, removed, added) {
    var model = get(this, 'owner'),
        name = get(this, 'name'),
        session = get(this, 'session');

    if(session) {
      session.modelWillBecomeDirty(model);
      if (!model._suspendedRelationships) {
        for (var i=index; i<index+removed; i++) {
          var inverseModel = this.objectAt(i);
          session.inverseManager.unregisterRelationship(model, name, inverseModel);
        }
      }
    }

    return this._super.apply(this, arguments);
  },

  arrayContentDidChange: function(index, removed, added) {
    this._super.apply(this, arguments);

    var model = get(this, 'owner'),
        name = get(this, 'name'),
        session = get(this, 'session');

    if (session && !model._suspendedRelationships) {
      for (var i=index; i<index+added; i++) {
        var inverseModel = this.objectAt(i);
        session.inverseManager.registerRelationship(model, name, inverseModel);
      }
    }
  },

});

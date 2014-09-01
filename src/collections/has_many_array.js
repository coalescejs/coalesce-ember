import ModelArray from './model_array';

var get = Ember.get, set = Ember.set;

export default ModelArray.extend({
  
  name: null,
  owner: null,
  session: Ember.computed.alias('owner.session'),
  
  replace: function(idx, amt, objects) {
    if(this.session) {
      objects = objects.map(function(model) {
        return this.session.add(model);
      }, this);
    }
    return this._super(idx, amt, objects);
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

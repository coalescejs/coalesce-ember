var get = Ember.get, set = Ember.set;

export default Ember.ArrayProxy.extend({
  session: null,
  type: null,
  params: null,

  init: function() {
    if(!get(this, 'content')) {
      set(this, 'content', []);
    }
    this._super.apply(this, arguments);
  },
  
  invalidate: function() {
    return this.get("session").invalidateQuery(this);
  },
  
  refresh: function() {
    return this.get("session").refreshQuery(this);
  }
  
});

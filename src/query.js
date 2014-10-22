var get = Ember.get, set = Ember.set;

var Query = Ember.ArrayProxy.extend({
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
  },

  // primitive for array support.
  replace: function(idx, amt, objects) {
    // if we replaced exactly the same number of items, then pass only the
    // replaced range. Otherwise, pass the full remaining array length
    // since everything has shifted
    var len = objects ? objects.length : 0;
    this.arrayContentWillChange(idx, amt, len);

    if (len === 0) {
      this.splice(idx, amt);
    } else {
      replace(this, idx, amt, objects);
    }

    this.arrayContentDidChange(idx, amt, len);
    return this;
  },
});

function replace(array, idx, amt, objects) {
  var args = [].concat(objects), chunk, ret = [],
    // https://code.google.com/p/chromium/issues/detail?id=56588
  size = 60000, start = idx, ends = amt, count;

  while (args.length) {
    count = ends > size ? size : ends;
    if (count <= 0) { count = 0; }

    chunk = args.splice(0, size);
    chunk = [start, count].concat(chunk);

    start += size;
    ends -= count;

    ret = ret.concat(splice.apply(array, chunk));
  }
  return ret;
}

export default Query;

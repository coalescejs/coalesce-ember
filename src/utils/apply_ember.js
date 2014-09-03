/**
  Utility method to mixin Ember's Prototype/Class chain into an existing constructor/prototype.
  
  The one caveat currently is that no arguments will be passed to the constructor.
  
  @method mixinEmber
  @param {Function} Type the constructor
  @param {Array} specialClassKeys class properties which Ember cannot handle (e.g. ones with getters)
  @param {...Mixin} mixins mixins to apply to the new class
  @return the extended Type
*/

var CoreObject = Ember.CoreObject,
    Mixin = Ember.Mixin;

export default function applyEmber(Type, specialClassKeys=[], ...mixins) {
  function cstor() {
    return CoreObject.apply(this);
  }

  var PrototypeMixin = Mixin.create(CoreObject.PrototypeMixin);
  PrototypeMixin.ownerConstructor = cstor;
  cstor.PrototypeMixin = PrototypeMixin;
  cstor.prototype = Object.create(Type.prototype);
  
  // These static properties use getters and do not play well with ClassMixin
  var SpecialClassProps = {};
  for(var key in Type) {
    if(!Type.hasOwnProperty(key)) continue;
    if(specialClassKeys.indexOf(key) !== -1) continue;
    SpecialClassProps[key] = Type[key];
  }

  var ClassMixin = Mixin.create(SpecialClassProps, CoreObject.ClassMixin);
  ClassMixin.reopen({
    extend: function() {
      var klass = this._super.apply(this, arguments);
      specialClassKeys.forEach(function(name) {
        var desc = Object.getOwnPropertyDescriptor(Type, name);
        Object.defineProperty(klass, name, desc);
      });
      return klass;
    }
  });

  ClassMixin.apply(cstor);
  ClassMixin.ownerConstructor = cstor;
  cstor.ClassMixin = ClassMixin;

  cstor.proto = function() {
    return this.prototype;
  }

  mixins.unshift({
    init: function() {
      Type.apply(this, arguments);
      this._super.apply(this, arguments);
    }
  });
  return cstor.extend.apply(cstor, mixins);
}

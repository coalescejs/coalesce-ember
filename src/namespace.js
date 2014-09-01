/**
  @module coalesce
*/

/**
  All Ember Data methods and functions are defined inside of this namespace.

  @class Cs
  @static
*/

var Cs;
if ('undefined' === typeof Cs) {
  /**
    @property VERSION
    @type String
    @default '<%= versionStamp %>'
    @static
  */
  Cs = Ember.Namespace.create({
    VERSION: 'VERSION_STRING_PLACEHOLDER'
  });
}

export default Cs;

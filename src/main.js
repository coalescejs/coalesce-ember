import Cs from './namespace';
import Coalesce from 'coalesce';

import './initializers';

import Model from './model/model';
import {attr, hasMany, belongsTo} from './model/model';
import HasManyArray from './collections/has_many_array';

Cs.Model = Model;
Cs.attr = attr;
Cs.hasMany = hasMany;
Cs.belongsTo = belongsTo;

Coalesce.Promise = Ember.RSVP.Promise;
Coalesce.ajax = Ember.$.ajax;
Coalesce.run = Ember.run;
Coalesce.HasManyArray = HasManyArray;

// Merge in Coalesce namespace
_.defaults(Cs, Coalesce);

export default Cs;

import Cs from './namespace';
import Coalesce from 'coalesce';

import './initializers';

import Model from './model/model';
import {attr, hasMany, belongsTo} from './model/model';
import HasManyArray from './collections/has_many_array';
import EmberSession from './session';
import PromiseArray from './promise';

Cs.Model = Model;
Cs.attr = attr;
Cs.hasMany = hasMany;
Cs.belongsTo = belongsTo;
Cs.EmberSession = EmberSession;

Coalesce.Promise = Ember.RSVP.Promise;
Coalesce.PromiseArray = PromiseArray;
Coalesce.ajax = Ember.$.ajax;
Coalesce.run = Ember.run;

// Merge in Coalesce namespace
_.defaults(Cs, Coalesce);

export default Cs;

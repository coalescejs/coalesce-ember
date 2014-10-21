import Session from 'coalesce/session/session';
import {ModelPromise, PromiseArray} from './promise';
import Query from './query';

/**
  @class Session
  
  Similar to the core Coalesce.js session, but with additional Ember.js
  niceties.
*/
export default class EmberSession extends Session {

  /**
    Ensures data is loaded for a model.

    @returns {Promise}
  */
  loadModel(model, opts) {
    return ModelPromise.create({
      content: model,
      promise: super.loadModel(model, opts)
    });
  }

  /**
    Queries the server and returns a descendent of Ember.ArrayProxy
    
    @param {Type} type Type to query against
    @param {object} params Query parameters
    @param {object} opts Additional options
    @return {PromiseArray}
  */
  query(type, query, opts) {
    return PromiseArray.create({
      promise: super.query(type, query, opts)
    });
  }

  /**
    Override buildQuery to be sure we receive an ArrayProxy descendent

    @return {CoalesceEmber.Query}
  */
  buildQuery(type, params) {
    type = this.typeFor(type);
    var newQuery = Query.create({
      session: this,
      type: type,
      params: params
    });
    return newQuery;
  }

}

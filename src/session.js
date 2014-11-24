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

  /**
    Override loadFromStorage so that the session's query cache queries values are of a Ember type Query
    @return {Promise}
  */
  static loadFromStorage(session){
    return super.loadFromStorage(session).then(function(session){
        session.queryCache.forEachQuery(function(value){
          
          var coalesceEmberQuery = this.buildQuery(value.type, value.params);

          coalesceEmberQuery.set('content', value.toArray());

          return coalesceEmberQuery;
        }, session);

        return session;
    });
  }

  /**
    Queries the server and bypasses the cache.

    @param {query} The Query to be refreshed
    @param {opts} opts Additional options
    @return {Promise}
  */
  //This method was copied here from Coalesce solely for the purpose of calling query.length with the get() accessor.
  //TODO consider drying this up somehow.
  refreshQuery(query, opts) {
    // TODO: for now we populate the query in the session, eventually this
    // should be done in the adapter layer a la models
    var promise = this.adapter.query(query.type.typeKey, query.params, opts, this).then(function(models) {
      query.meta = models.meta;
      query.replace(0, query.get('length'), models);
      return query;
    });
    this.queryCache.add(query, promise);
    
    return promise;
  }


  /**
    Mark a model as clean. This will prevent future
    `flush` calls from persisting this model's state to
    the server until the model is marked dirty again.

    @method markClean
    @param {Coalesce.Model} model
  */
  markClean(model) {
    // as an optimization, model's without shadows
    // are assumed to be clean
    this.shadows.remove(model);
    Ember.propertyDidChange(model, 'isDirty');
  }

  /**
    Mark a model as dirty by touching it.
    In essense, this really copies it to the shadow array if it isnt there.

    @method modelWillBecomeDirty
    @param {Coalesce.Mode} model
  */
  modelWillBecomeDirty(model) {
    if(this._dirtyCheckingSuspended) {
      return;
    }
    this.touch(model);
    Ember.propertyDidChange(model, 'isDirty');
  }


}

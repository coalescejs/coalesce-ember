`import {setupApp, teardownApp} from './support/app'`
`import Model from 'coalesce-ember/model/model'`
`import {attr, hasMany, belongsTo} from 'coalesce-ember/model/model'`
`import Attribute from 'coalesce/model/attribute'`
`import BelongsTo from 'coalesce/model/belongs_to'`
`import HasMany from 'coalesce/model/has_many'`
`import Errors from 'coalesce-ember/model/errors'`

describe 'integration', ->

  beforeEach ->
    setupApp.apply(this)
    App = @App
    class User extends Model
      name: attr 'string'
    User.typeKey = 'user'
    @User = User
    @container.register('model:user', User)
    true
    
  afterEach ->
    teardownApp.apply(this)
    
    
  describe 'errors', ->
    
    it 'should use custom errors object', ->
      @server.respondWith "POST", "/users", (xhr, url) ->
        xhr.respond 422, { "Content-Type": "application/json" }, JSON.stringify({errors: {name: 'is dumb'}})
        
      user = @session.create('user', name: 'wes')
      
      @session.flush().then null, ->
        expect(user.errors).to.be.an.instanceOf(Errors)
        expect(user.errors.name).to.eq('is dumb')
      

      

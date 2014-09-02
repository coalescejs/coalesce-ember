`import {setupApp, teardownApp} from './support/app'`
`import Model from 'coalesce-ember/model/model'`
`import {attr, belongsTo, hasMany} from 'coalesce-ember/model/model'`

describe "relationships", ->
  beforeEach ->
    setupApp.apply(this)
    
  afterEach ->
    teardownApp.apply(this)

  context 'one->many', ->

    beforeEach ->
      class @User extends Model
        name: attr 'string'
      @User.typeKey = 'user'
      
      class @Post extends Model
        title: attr 'string'
        user: belongsTo 'user'
        comments: hasMany 'comment'
      @Post.typeKey = 'post'
      
      class @Comment extends Model
        text: attr 'string'
        post: belongsTo 'post'
      @Comment.typeKey = 'comment'

      @container.register 'model:post', @Post
      @container.register 'model:comment', @Comment
      @container.register 'model:user', @User

    it 'should use Ember.ArrayProxy for hasMany', ->
      expect(@Post.create().comments).to.be.an.instanceOf(Ember.ArrayProxy)

    it 'supports watching belongsTo properties that have a detached cached value', ->
      deferred = Ember.RSVP.defer()
      @session.loadModel = (model) ->
        Ember.unwatchPath comment, 'post.title'
        deferred.resolve()
      comment = @session.adopt @session.build 'comment', id: 2, post: @Post.create(id: 1)

      Ember.run ->
        Ember.watchPath comment, 'post.title'
      deferred.promise

    it 'supports watching multiple levels of unloaded belongsTo', ->
      deferred = Ember.RSVP.defer()
      Post = @Post
      User = @User
      @session.loadModel = (model) ->
        if model instanceof Post
          model = model.copy()
          model.title = 'post'
          model.user = User.create id: "2"
          @merge(model)
          Ember.RSVP.resolve(model)
        else
          deferred.resolve()
      comment = @session.adopt @session.build 'comment', id: 2, post: @Post.create(id: 1)

      Ember.run ->
        Ember.watchPath comment, 'post.user.name'
      deferred.promise.then ->
        Ember.unwatchPath comment, 'post.user.name'

`import setupContainer from 'coalesce/ember/setup_container'`
`import {userWithPost, groupWithMembersWithUsers} from '../support/schemas'`
`import Model from 'coalesce/model/model'`

describe "relationships", ->
  beforeEach ->
    @App = Ember.Namespace.create()
    @container = new Ember.Container()
    setupContainer(@container)
    Coalesce.__container__ = @container
    @adapter = @container.lookup('adapter:main')
    @session = @adapter.newSession()


  context 'one->many', ->

    beforeEach ->
      `class User extends Model {}`
      User.defineSchema
        typeKey: 'user'
        attributes:
          name: {type: 'string'}
      @App.User = @User = User

      `class Post extends Model {}`
      Post.defineSchema
        typeKey: 'post'
        attributes:
          title: {type: 'string'}
        relationships:
          user: {kind: 'belongsTo', type: 'user'}
          comments: {kind: 'hasMany', type: 'comment'}
      @App.Post = @Post = Post

      `class Comment extends Model {}`
      Comment.defineSchema
        typeKey: 'comment'
        attributes:
          text: {type: 'string'}
        relationships:
          post: {kind: 'belongsTo', type: 'post'}
      @App.Comment = @Comment = Comment

      @container.register 'model:post', Post
      @container.register 'model:comment', Comment
      @container.register 'model:user', User


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

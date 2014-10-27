`import {setupApp, teardownApp} from './support/app'`
`import Model from 'coalesce-ember/model/model'`
`import {attr, hasMany, belongsTo} from 'coalesce-ember/model/model'`
`import Attribute from 'coalesce/model/attribute'`
`import BelongsTo from 'coalesce/model/belongs_to'`
`import HasMany from 'coalesce/model/has_many'`
`import Errors from 'coalesce-ember/model/errors'`
`import Coalesce from 'coalesce'`
`import EmberSession from 'coalesce-ember/session'`

describe 'integration', ->

  beforeEach ->
    setupApp.apply(this)
    App = @App

    class @User extends Model
      name: attr 'string'
      posts: hasMany 'post'
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

  describe 'save and load from storage', ->

    beforeEach ->

      @UserSerializer = Coalesce.ModelSerializer.extend
        typeKey: 'user'

      @container.register 'serializer:user', @UserSerializer

      @PostSerializer = Coalesce.ModelSerializer.extend
        typeKey: 'post'

      @container.register 'serializer:post', @PostSerializer

      @CommentSerializer = Coalesce.ModelSerializer.extend
        typeKey: 'post'

      @container.register 'serializer:comment', @CommentSerializer

    it "should persist session state between saving and loading to storage", ->

      user1 = @session.create "user",
        name: "Bob"

      user2 = @session.create "user",
        name: "Jim"

      post1 = @session.create "post",
        title: "Bobs first post"

      post2 = @session.create "post",
        title: "Bobs second post"

      post3 = @session.create "post",
        title: "Jims first post"

      post4 = @session.create "post",
        title: "Jims second post"

      comment1 = @session.create "comment",
        text: "comment 1"

      comment2 = @session.create "post",
        text: "comment 2"

      comment3 = @session.create "post",
        title: "comment 3"

      comment4 = @session.create "post",
        title: "comment 4"

      user1.get('posts').pushObject post1
      user1.get('posts').pushObject post2
      user2.get('posts').pushObject post3
      user2.get('posts').pushObject post4

      post1.get('comments').pushObject comment1
      post2.get('comments').pushObject comment2
      post3.get('comments').pushObject comment3
      post4.get('comments').pushObject comment4

      session = @session
      container = @container
      
      expect(session.idManager.uuid).to.eq(11)
      
      expect(session.models.size).to.eq(10)

      EmberSession.saveToStorage(session).then ->
        debugger
        newSession = session.newSession()

        EmberSession.loadFromStorage(newSession).then ->
          debugger
          expect(newSession.idManager.uuid).to.eq(11)
          expect(newSession.models.size).to.eq(10)
        

  describe 'online and offline crud', ->

    it 'should retain isDeleted on flush error', ->
      session = @session
      server = @server

      server.respondWith "POST", "/users", (xhr, url) ->
        xhr.respond 200, { "Content-Type": "application/json" }, JSON.stringify({users: [{id: 1, name:"Jerry", client_rev:1, client_id:"user1"}]})
        
      user = session.create('user', name: 'Jerry')

      session.flush().then((->
        expect(session.newModels.size).to.eq(0)
        expect(session.models[0].get('name')).to.eq('Jerry')
        expect(session.models[0].get('isNew')).to.be.false
        expect(session.models[0].get('id')).to.eq('1')

        # go offline
        server.respondWith "DELETE", "/users/1", (xhr, url) ->
          xhr.respond 0, null, null

        session.deleteModel(user)

        expect(session.models[0].get('isDeleted')).to.be.true

        session.flush().then(null,(->
          expect(session.models[0].get('isDeleted')).to.be.true

          # next to add putting server back online
          # issueing flush
          # and checking model set collections and flags
        ))
      ),(->
        
      ))
    # create 3 users, go offline, delete them all, go online, flush, check that all are indeed deleted
    # it 'should delete all (offline) deleted records after coming back online', ->
    #   session = @session
    #   server = @server

    #   server.respondWith "POST", "/users", (xhr, url) ->
    #     xhr.respond 200, { "Content-Type": "application/json" }, JSON.stringify({users: [{id: 1, name:"Jerry", client_rev:1, client_id:"user1"}]})
        
    #   user = session.create('user', name: 'Jerry')

    #   server.respondWith "POST", "/users", (xhr, url) ->
    #     xhr.respond 200, { "Content-Type": "application/json" }, JSON.stringify({users: [{id: 2, name:"Bob", client_rev:1, client_id:"user2"}]})
        
    #   user2 = session.create('user', name: 'Phil')

    #   server.respondWith "POST", "/users", (xhr, url) ->
    #     xhr.respond 200, { "Content-Type": "application/json" }, JSON.stringify({users: [{id: 3, name:"Phil", client_rev:1, client_id:"user3"}]})
        
    #   user3 = session.create('user', name: 'Jerry')
      
    #   session.flush().then ->

    #     # go offline
    #     server.respondWith "DELETE", "/users/1", (xhr, url) ->
    #       xhr.respond 0, null, null

    #     session.deleteModel(user)

    #     session.flush().then ->

    #       server.respondWith "DELETE", "/users/2", (xhr, url) ->
    #         xhr.respond 0, null, null

    #       session.deleteModel(user2)

    #       debugger 
    #       session.flush().then ->
    #         server.respondWith "DELETE", "/users/3", (xhr, url) ->
    #           xhr.respond 0, null, null

    #         session.deleteModel(user3)

    #         session.flush().then ->

    #           server.respondWith "DELETE", "/users/1", (xhr, url) ->
    #             xhr.respond 204, {}, null

    #           server.respondWith "DELETE", "/users/2", (xhr, url) ->
    #             xhr.respond 204, {}, null

    #           server.respondWith "DELETE", "/users/3", (xhr, url) ->
    #             xhr.respond 204, {}, null

    #           session.flush().then ->
    #             # CHECK THAT THE OBJECTS ARE DELETED!

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
        typeKey: 'comment'

      @container.register 'serializer:comment', @CommentSerializer

    it "should persist session state between saving and loading to storage", ->
      server = @server

      container = @container

      mainSession = @session
      session = mainSession.newSession()

      postSerializer = container.lookup('serializer:post')

      user1 = session.create 'user',
        name: "Bob"

      user2 = session.create 'user',
        name: "Jim"

      post1 = session.create "post",
        title: "Bobs first post"

      post2 = session.create "post",
        title: "Bobs second post"

      post3 = session.create "post",
        title: "Jims first post"

      post4 = session.create "post",
        title: "Jims second post"

      comment1 = session.create "comment",
        text: "comment 1"

      comment2 = session.create "comment",
        text: "comment 2"

      comment3 = session.create "comment",
        title: "comment 3"

      comment4 = session.create "comment",
        title: "comment 4"

      user1.get('posts').pushObject post1
      user1.get('posts').pushObject post2
      user2.get('posts').pushObject post3
      user2.get('posts').pushObject post4

      post1.get('comments').pushObject comment1
      post1.get('comments').pushObject comment2
      post1.get('comments').pushObject comment3
      post1.get('comments').pushObject comment4

      server.respondWith "POST", "/users", (xhr, url) ->
        xhr.respond 204, { "Content-Type": "application/json" }, ""

      server.respondWith "POST", "/posts", (xhr, url) ->
        xhr.respond 204, { "Content-Type": "application/json" }, ""

      server.respondWith "POST", "/comments", (xhr, url) ->
        xhr.respond 204, { "Content-Type": "application/json" }, ""

      # hack so that we can flush without having the server respond with proper ids
      user1.set('id',1)
      user2.set('id',2)

      post1.set('id',1)
      post2.set('id',2)
      post3.set('id',3)
      post4.set('id',4)

      comment1.set('id',1)
      comment2.set('id',2)
      comment3.set('id',3)
      comment4.set('id',4)
      # end of hack

      expect(user1.get('posts.length')).to.eq(2)

      seralizedPost1 = postSerializer.serialize(post1)
      seralizedPost2 = postSerializer.serialize(post2)
      seralizedPost3 = postSerializer.serialize(post3)
      seralizedPost4 = postSerializer.serialize(post4)

      postFlush = (arg) ->      
        expect(session.idManager.uuid).to.eq(11)
        
        expect(session.models.size).to.eq(10)

        EmberSession.saveToStorage(session).then (_session) ->
          EmberSession.loadFromStorage(mainSession.newSession()).then (_newSession) ->
            expect(_newSession.idManager.uuid).to.eq(11)
            expect(_newSession.models.size).to.eq(10)

            user = _newSession.load('user', 1).get('content')
            expect(user.get('posts.length')).to.eq(2)
            expect(user.get('posts.firstObject.comments.length')).to.eq(4)

            response = "["+seralizedPost1+","+seralizedPost2+","+seralizedPost3+","+seralizedPost4+"]"

            # offline call to query posts
            server.respondWith "GET", "/posts", (xhr, url) ->
              xhr.respond 0, null, null

            # server.respondWith "GET", "/posts", (xhr, url) ->
            #   xhr.respond 204, { "Content-Type": "application/json" }, response

            _newSession.query('post').then(((posts) ->
              
            ),( (error) ->
               expect(error).to.be.null
            ))


      session.flush().then(postFlush, postFlush)


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
    #     debugger
    #     # go offline
    #     # server.respondWith "DELETE", "/users/1", (xhr, url) ->
    #     #   xhr.respond 0, {}, ""

    #     #session.deleteModel(user)

    #     session.flush().then ->
    #       debugger
    #       server.respondWith "DELETE", "/users/2", (xhr, url) ->
    #         xhr.respond 0, {}, ""

    #       session.deleteModel(user2)

           
    #       session.flush().then ->
    #         server.respondWith "DELETE", "/users/3", (xhr, url) ->
    #           xhr.respond 0, {}, ""

    #         session.deleteModel(user3)

    #         session.flush().then ->

    #           server.respondWith "DELETE", "/users/1", (xhr, url) ->
    #             xhr.respond 204, {}, ""

    #           server.respondWith "DELETE", "/users/2", (xhr, url) ->
    #             xhr.respond 204, {}, ""

    #           server.respondWith "DELETE", "/users/3", (xhr, url) ->
    #             xhr.respond 204, {}, ""

    #           session.flush().then ->
    #             # CHECK THAT THE OBJECTS ARE DELETED!

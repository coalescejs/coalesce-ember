`import {setupApp, teardownApp, setupUserWithPosts} from './support/app'`
`import Model from 'coalesce-ember/model/model'`
`import {attr, hasMany, belongsTo} from 'coalesce-ember/model/model'`
`import Attribute from 'coalesce/model/attribute'`
`import BelongsTo from 'coalesce/model/belongs_to'`
`import HasMany from 'coalesce/model/has_many'`
`import Errors from 'coalesce-ember/model/errors'`
`import Coalesce from 'coalesce'`
`import Container from 'coalesce-ember/container'`

describe 'integration', ->

  beforeEach ->
    setupApp.apply(this)
    App = @App

    class @User extends Model
      name: attr 'string'
      posts: hasMany 'post'
      roles: hasMany 'role'
    @User.typeKey = 'user'
    
    class @Post extends Model
      title: attr 'string'
      user: belongsTo 'user'
      comments: hasMany 'comment'
    @Post.typeKey = 'post'

    class @Role extends Model
      name: attr 'string'
      user: belongsTo 'user'
    @Role.typeKey = 'role'
    
    class @Comment extends Model
      text: attr 'string'
      meta1: attr 'string'
      meta2: attr 'string'
      post: belongsTo 'post'
    @Comment.typeKey = 'comment'

    @container.register 'model:post', @Post
    @container.register 'model:comment', @Comment
    @container.register 'model:user', @User
    @container.register 'model:role', @Role

    @UserSerializer = Coalesce.ModelSerializer.extend
      typeKey: 'user'

    @container.register 'serializer:user', @UserSerializer

    @PostSerializer = Coalesce.ModelSerializer.extend
      typeKey: 'post'

    @container.register 'serializer:post', @PostSerializer

    @RoleSerializer = Coalesce.ModelSerializer.extend
      typeKey: 'role'

    @container.register 'serializer:role', @RoleSerializer

    @CommentSerializer = Coalesce.ModelSerializer.extend
      typeKey: 'comment'

    @container.register 'serializer:comment', @CommentSerializer

    true
    
  afterEach (done) ->
    teardownApp.apply(this) 
    
    @session.clearStorage().then ->
      done()

  describe 'relations and session flushing', ->
    it 'with existing parent creating multiple children in multiple flushes', ->
      self = @
      session = @session
      server = @server

      server.respondWith "GET", "/users", (xhr, url) ->
        response = users: {id: 1,  name: 'parent',  client_id: null, client_rev: null, rev: 0}
        xhr.respond 200, { "Content-Type": "application/json" }, JSON.stringify(response)

      session.query('user').then(((models) ->
        
        server.respondWith "GET", "/users/1", (xhr, url) ->
          response = users: {id: 1,  name: 'parent', posts: [], roles: [],  client_id: null, client_rev: null, rev: 1}, posts: [], roles: []
          xhr.respond 200, { "Content-Type": "application/json" }, JSON.stringify(response)

        _user = models.firstObject

        expect(_user.posts).to.be.undefined
        expect(_user.roles).to.be.undefined

        _user.refresh().then(((user) ->
          expect(user.posts).to.not.be.undefined
          expect(user.roles).to.not.be.undefined

          post = session.create('post', title: 'child 1', user: user)

          server.respondWith "POST", "/posts", (xhr, url) ->
            response = posts: {id: 1, title: post.title, user_id: post.userId, client_id: post.clientId, client_rev: post.clientRev, rev: 0}
            xhr.respond 200, { "Content-Type": "application/json" }, JSON.stringify(response)

          session.flush().then((->
              expect(user.posts.length).to.eq(1)
              expect(user.roles.length).to.eq(0)

              role = session.create('role', name: 'child 2', user: user)

              server.respondWith "POST", "/roles", (xhr, url) ->
                response = roles: {id: 1, name: role.name, user_id: role.userId, client_id: role.clientId, client_rev: role.clientRev, rev: 0}
                xhr.respond 200, { "Content-Type": "application/json" }, JSON.stringify(response)

              session.flush().then(((models)->
                expect(_user.posts.length).to.eq(1)
                expect(_user.roles.length).to.eq(1)
              ),((e) -> expect("SHOULDN't GET HERE").to.be.null))
          ),((e) -> expect("SHOULDN't GET HERE").to.be.null))
        ),((e) -> expect("SHOULDN't GET HERE").to.be.null))
      ),((e) -> expect("SHOULDN't GET HERE").to.be.null))

  describe 'failed flushing in offline', ->
    it "should preserve fields and relations", ->
      user = @session.merge @User.create( id: "1", name: 'Jerry', posts: [@Post.create( id: "1" )])
      post = @session.merge @Post.create( id: "1", user: user, title: "posting ish", comments: [])
      comment = @session.create('comment', post: post, text: "New comment")

      @server.respondWith "POST", "/users", (xhr, url) ->
          xhr.respond 0, null, null

      @server.respondWith "POST", "/posts", (xhr, url) ->
          xhr.respond 0, null, null

      @server.respondWith "POST", "/comments", (xhr, url) ->
          xhr.respond 0, null, null

      @session.flush().then null, (e) ->
        expect(post.title).to.eq("posting ish")
        expect(user.name).to.eq("Jerry")
        expect(comment.text).to.eq("New comment")

        expect(user.posts.firstObject).to.eq(post)
        expect(post.user).to.eq(user)

        expect(comment.post).to.eq(post)
        expect(user.posts.firstObject.comments.firstObject).to.eq(comment)

  describe 'errors', ->
    
    it 'should use custom errors object', ->
      @server.respondWith "POST", "/users", (xhr, url) ->
        xhr.respond 422, { "Content-Type": "application/json" }, JSON.stringify({errors: {name: 'is dumb'}})
        
      user = @session.create('user', name: 'wes')
      
      @session.flush().then null, ->
        expect(user.errors).to.be.an.instanceOf(Errors)
        expect(user.errors.name).to.eq('is dumb')

  describe 'save and load from storage', ->
    afterEach ->
      # have to tear down again cause we re setup app in 'should retain relationships'
      teardownApp.apply(@) 


    it 'should retain relationships', ->

      self = @
      session = @session
      server = @server

      session.clearStorage().then ->
        server.respondWith "POST", "/users", (xhr, url) ->
          xhr.respond 200, { "Content-Type": "application/json" }, JSON.stringify({users: [{id: 1, name:"Jerrys", client_rev: 1, client_id: "user1"}]})
          
        user = session.create('user', name: 'Jerry')
        
        session.flush().then ->

          # create/add posts
          post = session.create('post', name: 'title1')
          user.posts.pushObject post

          server.respondWith "POST", "/posts", (xhr, url) ->
            users = [{id: 1, name:"Jerry", client_rev: 2, client_id: "user1", posts:[1]}]
            posts = [{id: 1, title:"title1", client_rev: 1, client_id: "post2", user_id: 1}]

            xhr.respond 200, { "Content-Type": "application/json" }, JSON.stringify({users: users, posts: posts})

          # flush
          session.flush().then ->
            session.saveToStorage(session).then (_session) ->
              # go offline
              # reset app
              teardownApp.apply(self) 
              setupApp.apply(self)
              App = self.App

              class self.User extends Model
                name: attr 'string'
                posts: hasMany 'post'
              self.User.typeKey = 'user'
              
              class self.Post extends Model
                title: attr 'string'
                user: belongsTo 'user'
                comments: hasMany 'comment'
              self.Post.typeKey = 'post'
              
              class self.Comment extends Model
                text: attr 'string'
                post: belongsTo 'post'
              self.Comment.typeKey = 'comment'

              self.container.register 'model:post', self.Post
              self.container.register 'model:comment', self.Comment
              self.container.register 'model:user', self.User
              
              session.loadFromStorage(self.session).then (session) ->
                user = session.load('user', 1)
                
                expect(user.posts.length).to.eq(1)
  
  describe 'save and load from storage', ->
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

      user1.posts.pushObject post1
      user1.posts.pushObject post2
      user2.posts.pushObject post3
      user2.posts.pushObject post4

      post1.comments.pushObject comment1
      post1.comments.pushObject comment2
      post1.comments.pushObject comment3
      post1.comments.pushObject comment4

      server.respondWith "POST", "/users", (xhr, url) ->
        xhr.respond 204, { "Content-Type": "application/json" }, "{}"

      server.respondWith "POST", "/posts", (xhr, url) ->
        xhr.respond 204, { "Content-Type": "application/json" }, "{}"

      server.respondWith "POST", "/comments", (xhr, url) ->
        xhr.respond 204, { "Content-Type": "application/json" }, "{}"

      # hack so that we can flush without having the server respond with proper ids
      user1.id = 1
      user2.id = 2

      post1.id = 1
      post2.id = 2
      post3.id = 3
      post4.id = 4

      comment1.id = 1
      comment2.id = 2
      comment3.id = 3
      comment4.id = 4
      # end of hack

      expect(user1.posts.length).to.eq(2)

      seralizedPost1 = postSerializer.serialize(post1)
      seralizedPost2 = postSerializer.serialize(post2)
      seralizedPost3 = postSerializer.serialize(post3)
      seralizedPost4 = postSerializer.serialize(post4)

      postFlush = (arg) ->      
        expect(session.idManager.uuid).to.eq(11)
        
        expect(session.models.size).to.eq(10)

        session.saveToStorage(session).then (_session) ->
          session.loadFromStorage(mainSession.newSession()).then (_newSession) ->
            expect(_newSession.idManager.uuid).to.eq(11)
            expect(_newSession.models.size).to.eq(10)

            user = _newSession.load('user', 1).content
            expect(user.posts.length).to.eq(2)
            expect(user.posts.firstObject.comments.length).to.eq(4)

            response = JSON.stringify([seralizedPost1, seralizedPost2, seralizedPost3, seralizedPost4])

            # offline call to query posts
            server.respondWith "GET", "/posts", (xhr, url) ->
              xhr.respond 0, null, null

            # server.respondWith "GET", "/posts", (xhr, url) ->
            #   xhr.respond 204, { "Content-Type": "application/json" }, response

            _newSession.query('post').then(((posts) ->
              
            ),( (error) ->
               expect(error.status).to.not.be.null
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
        expect(session.models[0].name).to.eq('Jerry')
        expect(session.models[0].isNew).to.be.false
        expect(session.models[0].id).to.eq('1')

        # go offline
        server.respondWith "DELETE", "/users/1", (xhr, url) ->
          xhr.respond 0, null, null

        session.deleteModel(user)

        expect(session.models[0].isDeleted).to.be.true

        session.flush().then(null,(->
          expect(session.models[0].isDeleted).to.be.true

          # next to add putting server back online
          # issueing flush
          # and checking model set collections and flags
        ))
      ),(->
        
      ))

    it 'should only send dirty fields', ->
      session = @session
      server = @server

      @server.respondWith "PUT", "/comments/1", (xhr, url) ->
        hash = JSON.parse xhr.requestBody
        
        expect(hash.comment.hasOwnProperty('text')).to.be.false 
        expect(hash.comment.hasOwnProperty('meta1')).to.be.true

        xhr.respond 200, { "Content-Type": "application/json" }, JSON.stringify(hash)

      comment = @session.merge @Comment.create
        id: "1",
        text: "this is text",
        meta1: "this is meta1",
        meta2: "this is meta2"
        

      comment.meta1 = "changeme"

      @session.flush()

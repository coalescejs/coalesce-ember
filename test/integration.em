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

    @UserSerializer = Coalesce.ActiveModelSerializer.extend
      typeKey: 'user'

    @container.register 'serializer:user', @UserSerializer

    @PostSerializer = Coalesce.ActiveModelSerializer.extend
      typeKey: 'post'

    @container.register 'serializer:post', @PostSerializer

    @RoleSerializer = Coalesce.ActiveModelSerializer.extend
      typeKey: 'role'

    @container.register 'serializer:role', @RoleSerializer

    @CommentSerializer = Coalesce.ActiveModelSerializer.extend
      typeKey: 'comment'

    @container.register 'serializer:comment', @CommentSerializer

    true
    
  afterEach (done) ->
    teardownApp.apply(this) 
    
    @session.clearStorage().then ->
      done()

  describe 'complex model graph', ->
    beforeEach ->
      class @School extends Model
        name: attr 'string'
        players: hasMany 'player'
      @School.typeKey = 'school'

      class @Player extends Model
        name: attr 'string'
        school: belongsTo 'school'
        position: belongsTo 'position'
        injuries: hasMany 'injury'
        evaluations: hasMany 'evaluation'
      @Player.typeKey = 'player'

      class @Injury extends Model
        name: attr 'string'
        player: belongsTo 'player'
      @Injury.typeKey = 'injury'

      class @Position extends Model
        name: attr 'string'
        factors: hasMany 'factor'
        positionfactors: hasMany 'positionfactor'
      @Position.typeKey = 'position'

      class @Factor extends Model
        name: attr 'string'
        factortype: belongsTo 'factortype'
        positionfactors: hasMany 'positionfactor'
      @Factor.typeKey = 'factor'

      class @FactorType extends Model
        name: attr 'string'
        factors: hasMany 'factor'
      @FactorType.typeKey = 'factortype'

      class @PositionFactor extends Model
        name: attr 'string'
        factor: belongsTo 'factor'
        position: belongsTo 'position'
      @PositionFactor.typeKey = 'positionfactor'

      class @Evaluation extends Model
        name: attr 'string'
        position: belongsTo 'position'
        player: belongsTo 'player'
        grades: hasMany 'grade'
      @Evaluation.typeKey = 'evaluation'

      class @Grade extends Model
        name: attr 'string'
        evaluation: belongsTo 'evaluation'
        factor: belongsTo 'factor'
      @Grade.typeKey = 'grade'


      @container.register 'model:school', @School
      @container.register 'model:player', @Player
      @container.register 'model:injury', @Injury
      @container.register 'model:position', @Position
      @container.register 'model:factor', @Factor
      @container.register 'model:factortype', @FactorType
      @container.register 'model:positionfactor', @PositionFactor
      @container.register 'model:evaluation', @Evaluation
      @container.register 'model:grade', @Grade

      @SchoolSerializer = Coalesce.ActiveModelSerializer.extend
        typeKey: 'school'

      @container.register 'serializer:school', @SchoolSerializer

      @PlayerSerializer = Coalesce.ActiveModelSerializer.extend
        typeKey: 'player'

      @container.register 'serializer:player', @PlayerSerializer

      @InjurySerializer = Coalesce.ActiveModelSerializer.extend
        typeKey: 'injury'

      @container.register 'serializer:injury', @InjurySerializer

      @PositionSerializer = Coalesce.ActiveModelSerializer.extend
        typeKey: 'position'

      @container.register 'serializer:position', @PositionSerializer

      @FactorSerializer = Coalesce.ActiveModelSerializer.extend
        typeKey: 'factor'

      @container.register 'serializer:factor', @FactorSerializer

      @FactorTypeSerializer = Coalesce.ActiveModelSerializer.extend
        typeKey: 'factortype'

      @container.register 'serializer:factortype', @FactorTypeSerializer

      @PositionFactorSerializer = Coalesce.ActiveModelSerializer.extend
        typeKey: 'positionfactor'
        factors:
          embedded: 'always'

      @container.register 'serializer:positionfactor', @PositionFactorSerializer

      @EvaluationSerializer = Coalesce.ActiveModelSerializer.extend
        typeKey: 'evaluation'

      @container.register 'serializer:evaluation', @EvaluationSerializer

      @GradeSerializer = Coalesce.ActiveModelSerializer.extend
        typeKey: 'grade'

      @container.register 'serializer:grade', @GradeSerializer

      @school = @session.merge @School.create( id: "1", name: 'USF')
      @position = @session.merge @Position.create( id: "1", name: 'QB')
      @factortype1 = @session.merge @FactorType.create( id: "1", name: 'FT1')
      # @factortype2 = @session.merge @FactorType.create( id: "2", name: 'FT2')
      # @factortype3 = @session.merge @FactorType.create( id: "3", name: 'FT3')
      @factor1 = @session.merge @Factor.create( id: "1", name: 'F1', factortype: @factortype1)
      # @factor2 = @session.merge @Factor.create( id: "2", name: 'F2', factortype: @factortype1)
      # @factor3 = @session.merge @Factor.create( id: "3", name: 'F3', factortype: @factortype1)
      # @factor4 = @session.merge @Factor.create( id: "4", name: 'F4', factortype: @factortype2)
      # @factor5 = @session.merge @Factor.create( id: "5", name: 'F5', factortype: @factortype2)
      # @factor6 = @session.merge @Factor.create( id: "6", name: 'F6', factortype: @factortype2)
      # @factor7 = @session.merge @Factor.create( id: "7", name: 'F7', factortype: @factortype3)
      # @factor8 = @session.merge @Factor.create( id: "8", name: 'F8', factortype: @factortype3)
      # @factor9 = @session.merge @Factor.create( id: "9", name: 'F9', factortype: @factortype3)

      @positionfactor1 = @session.merge @PositionFactor.create( id: "1", name: 'PF1', factor: @factor1, position: @position)
      # @positionfactor2 = @session.merge @PositionFactor.create( id: "2", name: 'PF2', factor: @factor2, position: @position)
      # @positionfactor3 = @session.merge @PositionFactor.create( id: "3", name: 'PF3', factor: @factor3, position: @position)
      # @positionfactor4 = @session.merge @PositionFactor.create( id: "4", name: 'PF4', factor: @factor4, position: @position)
      # @positionfactor5 = @session.merge @PositionFactor.create( id: "5", name: 'PF5', factor: @factor5, position: @position)
      # @positionfactor6 = @session.merge @PositionFactor.create( id: "6", name: 'PF6', factor: @factor6, position: @position)
      # @positionfactor7 = @session.merge @PositionFactor.create( id: "7", name: 'PF7', factor: @factor7, position: @position)
      # @positionfactor8 = @session.merge @PositionFactor.create( id: "8", name: 'PF8', factor: @factor8, position: @position)
      # @positionfactor9 = @session.merge @PositionFactor.create( id: "9", name: 'PF9', factor: @factor9, position: @position)

    it 'creating new flushes with errors sucessfully', ->
      self = @
      session = @session
      server = @server

      # non-new
      player = @session.merge @Player.create( id: "1", name: 'Jerry', school: @school, position: @position)

      # new
      evaluation = @session.create('evaluation', name: "5555555555", position: @position, player: player) #eval
      grade = @session.create('grade', name: "grade1", evaluation: evaluation, factor: @factor1) #grades
      # grade2 = @session.create('grade', name: "grade1", evaluation: evaluation, factor: @factor2) #grades
      # grade3 = @session.create('grade', name: "grade1", evaluation: evaluation, factor: @factor3) #grades
      # grade4 = @session.create('grade', name: "grade1", evaluation: evaluation, factor: @factor4) #grades
      # grade5 = @session.create('grade', name: "grade1", evaluation: evaluation, factor: @factor5) #grades
      # grade6 = @session.create('grade', name: "grade1", evaluation: evaluation, factor: @factor6) #grades
      # grade7 = @session.create('grade', name: "grade1", evaluation: evaluation, factor: @factor7) #grades
      # grade8 = @session.create('grade', name: "grade1", evaluation: evaluation, factor: @factor8) #grades
      # grade9 = @session.create('grade', name: "grade1", evaluation: evaluation, factor: @factor9) #grades

      server.respondWith "POST", "/evaluations", (xhr, url) ->
        if(evaluation.name == "5555555555")
          response = {errors: {name: ['is to long']}}
          xhr.respond 422, { "Content-Type": "application/json" }, JSON.stringify(response)
        else
          response = {evaluations: [{id: 1, name: evaluation.name, client_id: evaluation.clientId, client_rev: evaluation.clientRev, rev: 0}]}
          xhr.respond 200, { "Content-Type": "application/json" }, JSON.stringify(response)

      server.respondWith "POST", "/grades", (xhr, url) ->
        if(grade.name == "grade1")
          response = {errors: {name: ['is to long']}}
          xhr.respond 422, { "Content-Type": "application/json" }, JSON.stringify(response)
        else
          response = {grades: [{id: 1, name: grade.name, client_id: grade.clientId, client_rev: grade.clientRev, rev: 0}]}
          xhr.respond 200, { "Content-Type": "application/json" }, JSON.stringify(response)

      session.flush().then(((models)->
        expect("SHOULDN't GET HERE").to.be.null
      ),((errModels)-> 
        expect(evaluation.hasErrors).to.be.true
        expect(grade.hasErrors).to.be.false

        evaluation.name = "shorter"
          
        session.flush().then(((models)->
          expect("SHOULDN't GET HERE").to.be.null
        ),((errModels)-> 
          expect(evaluation.hasErrors).to.be.false
          expect(grade.hasErrors).to.be.true
          expect(evaluation.isNew).to.be.false
          expect(grade.isNew).to.be.true

          grade.name = "grade1-renamed"

          session.flush().then(((models)->
            expect(evaluation.hasErrors).to.be.false
            expect(grade.hasErrors).to.be.false
            expect(evaluation.isNew).to.be.false
            expect(grade.isNew).to.be.false
          ),((errModels)-> 
            expect("SHOULDN't GET HERE").to.be.null
          ))
        ))
      ))

    it 'updating flushes with errors sucessfully', ->
      self = @
      session = @session
      server = @server
      player = null
      evaluation = null
      injury = null

      server.respondWith "GET", "/players/1", (xhr, url) ->
        player = {id: 1, name: 'Jerry', position_id: 1, school_id: 1, evaluation_ids: [1], injury_ids: [1], client_id: null, client_rev: null, rev: 1}
        evaluation = {id: "1", name: '5555555555', player_id: 1, position_id: 1, client_id: null, client_rev: null, rev: 1}
        injury = {id: "1", name: '5555555555', player_id: 1, client_id: null, client_rev: null, rev: 1}
        response = {players: [player], evaluations: [evaluation], injuries: [injury]}
        xhr.respond 200, { "Content-Type": "application/json" }, JSON.stringify(response)

      server.respondWith "PUT", "/evaluations/1", (xhr, url) ->
        # debugger
        if(evaluation.name == "fail")
          response = {errors: {name: ['is to long']}}
          xhr.respond 422, { "Content-Type": "application/json" }, JSON.stringify(response)
        else
          response = {evaluations: [{id: 1, name: evaluation.name, client_id: evaluation.clientId, client_rev: evaluation.clientRev, rev: 2}]}
          xhr.respond 200, { "Content-Type": "application/json" }, JSON.stringify(response)

      server.respondWith "PUT", "/players/1", (xhr, url) ->
        # debugger
        if(player.name == "fail")
          response = {errors: {name: ['is to long']}}
          xhr.respond 422, { "Content-Type": "application/json" }, JSON.stringify(response)
        else
          response = {players: [{id: 1, name: player.name, client_id: player.clientId, client_rev: player.clientRev, rev: 2}]}
          xhr.respond 200, { "Content-Type": "application/json" }, JSON.stringify(response)

      server.respondWith "PUT", "/injuries/1", (xhr, url) ->
        # debugger
        if(injury.name == "fail")
          response = {errors: {name: ['is to long']}}
          xhr.respond 422, { "Content-Type": "application/json" }, JSON.stringify(response)
        else
          response = {injuries: [{id: 1, name: injury.name, client_id: injury.clientId, client_rev: injury.clientRev, rev: 2}]}
          xhr.respond 200, { "Content-Type": "application/json" }, JSON.stringify(response)

      session.load('player', 1).then (model) ->

        player = model
        
        expect(player.evaluations.size).to.not.eq(0)
        expect(player.injuries.size).to.not.eq(0)

        evaluation = player.evaluations.toArray()[0]
        injury = player.injuries.toArray()[0]
        
        player.name = "fail"
        evaluation.name = "fail"
        injury.name = "fail"

        session.flush().then(((models)->
          expect("SHOULDN't GET HERE").to.be.null
        ),((errModels)-> 
          errModels.forEach (model) ->
            if model.clientId == evaluation.clientId || model.clientId == player.clientId || model.clientId == injury.clientId
              expect(model.hasErrors).to.be.true
              expect(model.isDirty).to.be.true

          expect(evaluation.hasErrors).to.be.true
          expect(player.hasErrors).to.be.true
          expect(injury.hasErrors).to.be.true
          expect(evaluation.isDirty).to.be.true
          expect(player.isDirty).to.be.true
          expect(injury.isDirty).to.be.true

          evaluation.name = "nonfail"
            
          session.flush().then(((models)->
            expect("SHOULDN't GET HERE").to.be.null
          ),((errModels)-> 
            errModels.forEach (model) ->
              if model.clientId == evaluation.clientId
                expect(model.hasErrors).to.be.false
                expect(model.isDirty).to.be.false

              if model.clientId == player.clientId || model.clientId == injury.clientId
                expect(model.hasErrors).to.be.true
                expect(model.isDirty).to.be.true

            expect(evaluation.hasErrors).to.be.false
            expect(player.hasErrors).to.be.true
            expect(injury.hasErrors).to.be.true
            expect(evaluation.isDirty).to.be.false
            expect(player.isDirty).to.be.true
            expect(injury.isDirty).to.be.true

            player.name = "nonfail"

            session.flush().then(((models)->
              expect("SHOULDN't GET HERE").to.be.null
            ),((errModels)-> 
              errModels.forEach (model) ->
                if model.clientId == player.clientId || model.clientId == evaluation.clientId
                  expect(model.hasErrors).to.be.false
                  expect(model.isDirty).to.be.false

                if model.clientId == injury.clientId
                  expect(model.hasErrors).to.be.true
                  expect(model.isDirty).to.be.true

              expect(evaluation.hasErrors).to.be.false
              expect(player.hasErrors).to.be.false
              expect(injury.hasErrors).to.be.true
              expect(evaluation.isDirty).to.be.false
              expect(player.isDirty).to.be.false
              expect(injury.isDirty).to.be.true

              injury.name = "nonfail"

              session.flush().then(((models)->
                models.forEach (model) ->
                  if model.clientId == evaluation.clientId || model.clientId == player.clientId || model.clientId == injury.clientId
                    expect(model.hasErrors).to.be.false
                    expect(model.isDirty).to.be.false

                expect(evaluation.hasErrors).to.be.false
                expect(player.hasErrors).to.be.false
                expect(injury.hasErrors).to.be.false
                expect(evaluation.isDirty).to.be.false
                expect(player.isDirty).to.be.false
                expect(injury.isDirty).to.be.false
              ),((errModels)-> 
                expect("SHOULDN't GET HERE").to.be.null
              ))
            ))
          ))
        ))

  describe 'relations and session flushing', ->
    it 'with existing parent creating multiple children in multiple flushes', ->
      self = @
      session = @session
      server = @server

      server.respondWith "GET", "/users", (xhr, url) ->
        response = {users: [{id: 1,  name: 'parent',  client_id: null, client_rev: null, rev: 0}]}
        xhr.respond 200, { "Content-Type": "application/json" }, JSON.stringify(response)

      session.query('user').then(((models) ->
        
        server.respondWith "GET", "/users/1", (xhr, url) ->
          response = {users: [{id: 1,  name: 'parent', post_ids: [], role_ids: [],  client_id: null, client_rev: null, rev: 1}], posts: [], roles: []}
          xhr.respond 200, { "Content-Type": "application/json" }, JSON.stringify(response)

        _user = models.firstObject

        expect(_user.posts).to.be.undefined
        expect(_user.roles).to.be.undefined

        _user.refresh().then(((user) ->
          
          expect(user.posts).to.not.be.undefined
          expect(user.roles).to.not.be.undefined
          
          post = session.create('post', title: 'child 1', user: user)

          server.respondWith "POST", "/posts", (xhr, url) ->
            response = {posts: [{id: 1, title: post.title, user_id: post.userId, client_id: post.clientId, client_rev: post.clientRev, rev: 0}]}
            xhr.respond 200, { "Content-Type": "application/json" }, JSON.stringify(response)

          session.flush().then((->
              expect(user.posts.length).to.eq(1)
              expect(user.roles.length).to.eq(0)

              role = session.create('role', name: 'child 2', user: user)

              server.respondWith "POST", "/roles", (xhr, url) ->
                response = {roles: [{id: 1, name: role.name, user_id: role.userId, client_id: role.clientId, client_rev: role.clientRev, rev: 0}]}
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

      @session.flush().then ((e) -> expect("SHOULDN't GET HERE").to.be.null), (e) ->
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
      
      @session.flush().then ((e) -> expect("SHOULDN't GET HERE").to.be.null), ->
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
  
  # describe 'save and load from storage', ->
  #   it "should persist session state between saving and loading to storage", ->
  #     server = @server

  #     container = @container

  #     mainSession = @session
  #     session = mainSession.newSession()

  #     postSerializer = container.lookup('serializer:post')

  #     user1 = session.create 'user',
  #       name: "Bob"

  #     user2 = session.create 'user',
  #       name: "Jim"

  #     post1 = session.create "post",
  #       title: "Bobs first post"

  #     post2 = session.create "post",
  #       title: "Bobs second post"

  #     post3 = session.create "post",
  #       title: "Jims first post"

  #     post4 = session.create "post",
  #       title: "Jims second post"

  #     comment1 = session.create "comment",
  #       text: "comment 1"

  #     comment2 = session.create "comment",
  #       text: "comment 2"

  #     comment3 = session.create "comment",
  #       title: "comment 3"

  #     comment4 = session.create "comment",
  #       title: "comment 4"

  #     user1.posts.pushObject post1
  #     user1.posts.pushObject post2
  #     user2.posts.pushObject post3
  #     user2.posts.pushObject post4

  #     post1.comments.pushObject comment1
  #     post1.comments.pushObject comment2
  #     post1.comments.pushObject comment3
  #     post1.comments.pushObject comment4

  #     server.respondWith "POST", "/users", (xhr, url) ->
  #       xhr.respond 204, { "Content-Type": "application/json" }, "{}"

  #     server.respondWith "POST", "/posts", (xhr, url) ->
  #       xhr.respond 204, { "Content-Type": "application/json" }, "{}"

  #     server.respondWith "POST", "/comments", (xhr, url) ->
  #       xhr.respond 204, { "Content-Type": "application/json" }, "{}"

  #     # hack so that we can flush without having the server respond with proper ids
  #     user1.id = 1
  #     user2.id = 2

  #     post1.id = 1
  #     post2.id = 2
  #     post3.id = 3
  #     post4.id = 4

  #     comment1.id = 1
  #     comment2.id = 2
  #     comment3.id = 3
  #     comment4.id = 4
  #     # end of hack

  #     expect(user1.posts.length).to.eq(2)

  #     seralizedPost1 = postSerializer.serialize(post1)
  #     seralizedPost2 = postSerializer.serialize(post2)
  #     seralizedPost3 = postSerializer.serialize(post3)
  #     seralizedPost4 = postSerializer.serialize(post4)

  #     postFlush = (arg) ->      
  #       expect(session.idManager.uuid).to.eq(11)
        
  #       expect(session.models.size).to.eq(10)

  #       session.saveToStorage(session).then (_session) ->
  #         session.loadFromStorage(mainSession.newSession()).then (_newSession) ->
  #           expect(_newSession.idManager.uuid).to.eq(11)
  #           expect(_newSession.models.size).to.eq(10)

  #           user = _newSession.load('user', 1).content
  #           expect(user.posts.length).to.eq(2)
  #           expect(user.posts.firstObject.comments.length).to.eq(4)

  #           response = JSON.stringify([seralizedPost1, seralizedPost2, seralizedPost3, seralizedPost4])

  #           # offline call to query posts
  #           server.respondWith "GET", "/posts", (xhr, url) ->
  #             xhr.respond 0, null, null

  #           # server.respondWith "GET", "/posts", (xhr, url) ->
  #           #   xhr.respond 204, { "Content-Type": "application/json" }, response

  #           _newSession.query('post').then(((posts) ->
              
  #           ),( (error) ->
  #              expect(error.status).to.not.be.null
  #           ))


  #     session.flush().then(postFlush, postFlush)

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

        session.flush().then(((e) -> expect("SHOULDN't GET HERE").to.be.null),(->
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

`import {setupApp, teardownApp} from './support/app'`
`import Model from 'coalesce-ember/model/model'`
`import {attr, hasMany, belongsTo} from 'coalesce-ember/model/model'`
`import Attribute from 'coalesce/model/attribute'`
`import BelongsTo from 'coalesce/model/belongs_to'`
`import HasMany from 'coalesce/model/has_many'`

describe 'ember/model', ->

  session = null
  App = null

  beforeEach ->
    setupApp.apply(this)
    App = @App
    true
    
  afterEach ->
    teardownApp.apply(this)
  
  describe 'class definition', ->
  
    beforeEach ->
      class @Post extends Model
        title: attr 'string'
        titleDisplay: ~> @title && @title.toUpperCase()
        comments: hasMany 'comment'
      
      class @Comment extends Model
        post: belongsTo 'post'
        
      @container.register 'model:post', @Post
      @container.register 'model:comment', @Comment
  
    it 'supports computed properties', ->
      post = @Post.create(title: 'moby dick')
      expect(post.title).to.eq('moby dick')
      expect(post.titleDisplay).to.eq('MOBY DICK')
      
    it 'supports new()', ->
      post = new @Post()
      post.title = 'new?'
      expect(post.title).to.eq('new?')
      
    it 'supports mixins', ->
      mixin HasName
        nameDisplay: ~> @name.toUpperCase()
        
      class User extends Model with HasName
        name: attr 'string'
        
      user = User.create(name: 'test')
      expect(user.nameDisplay).to.eq('TEST')
      
    it 'populates field metadata', ->
      expect(@Post.fields.size).to.eq(2)
      postFactory = @container.lookupFactory('model:post')
      expect(postFactory.fields.size).to.eq(2)
      expect(@Post.create().constructor.fields.size).to.eq(2)
      expect(postFactory.create().constructor.fields.size).to.eq(2)
  
    describe 'schema macros', ->
    
      describe 'attr', ->
      
        it 'defines an attribute', ->
          expect(@Post.fields.get('title')).to.be.an.instanceOf(Attribute)
          
        it 'is observable', ->
          post = @Post.create(title: 'one')
          expect(post.title).to.eq('one')
          observerHit = false

          Ember.addObserver post, 'title', ->
            observerHit = true
          post.title = 'two'
          expect(post.title).to.eq('two')
          expect(observerHit).to.be.true
          
        it 'notifies dependencies', ->
          post = @Post.create(title: 'one')
          expect(post.titleDisplay).to.eq('ONE')
          observerHit = false

          Ember.addObserver post, 'titleDisplay', ->
            observerHit = true
          post.title = 'two'
          expect(post.titleDisplay).to.eq('TWO')
          expect(observerHit).to.be.true
        
      
      describe 'belongsTo', ->
      
        it 'defines a belongsTo relationships', ->
          expect(@Comment.fields.get('post')).to.be.an.instanceOf(BelongsTo)
          
        it 'is observable', ->
          post = @Post.create(comments: [])
          comment = @Comment.create(post: post)
          expect(comment.post).to.eq(post)
          
          observerHit = false

          Ember.addObserver comment, 'post', ->
            observerHit = true
          comment.post = null
          expect(observerHit).to.be.true
          
      describe 'hasMany', ->
        
        it 'defines a hasMany relationship', ->
          expect(@Post.fields.get('comments')).to.be.an.instanceOf(HasMany)
      
        
  describe 'subclassing', ->
  
    beforeEach ->
      class @User extends Model
        name: attr 'string'
      @User.typeKey = 'user'
      class @Admin extends @User
        role: attr 'string'
      @Admin.typeKey = 'admin'
        
    it 'can add fields', ->
      expect(@Admin.fields.get('role')).to.exist
      
    it 'inherits fields from parent', ->
      expect(@Admin.fields.get('name')).to.exist
    
    it 'does not modify the parent fields', ->
      expect(@User.fields.get('role')).to.not.exist
      
  describe '.isNew', ->
    
    it 'is observable', ->
      class User extends Model
        name: attr 'string'
      @container.register('model:user', User)
        
      user = @session.create 'user',
        name: 'Wes'

      expect(user.isNew).to.be.true
      observerHit = false

      Ember.addObserver user, 'isNew', ->
        expect(user.isNew).to.be.false
        observerHit = true

      @session.merge User.create(id: "1", name: 'Wes', clientId: user.clientId)
      expect(user.isNew).to.be.false
      expect(observerHit).to.be.true
      
  describe '.isDirty', ->
    
    xit 'is observable', ->
      user = session.merge new @User
        id: '1'
        name: 'Wes'

      expect(user.isDirty).to.be.false
      observerHit = false

      Ember.addObserver user, 'isDirty', ->
        expect(user.isDirty).to.be.true
        observerHit = true

      user.name = 'Brogrammer'
      expect(user.isDirty).to.be.true
      expect(observerHit).to.be.true

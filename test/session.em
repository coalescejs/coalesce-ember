`import Model from 'coalesce-ember/model/model'`
`import {attr, belongsTo, hasMany} from 'coalesce-ember/model/model'`
`import {setupApp, teardownApp} from './support/app'`

describe 'Session', ->

  beforeEach ->
    setupApp.apply(this)
    
  afterEach ->
    teardownApp.apply(this)
  
      
  describe '.isDirty', ->
  
    beforeEach ->
      class @Post extends Model
        title: attr 'string'
      @Post.typeKey = 'post'
  
    it 'is true when model is dirty', ->
      post = @session.merge @Post.create(title: 'sup', id: "1")
      expect(@session.isDirty).to.be.false
      post.title = 'bro'
      expect(@session.isDirty).to.be.true

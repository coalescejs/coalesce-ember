`import Coalesce from 'coalesce'`
`import Model from 'coalesce-ember/model/model'`
`import {ModelPromise, PromiseArray} from 'coalesce-ember/promise'`
`import {attr, belongsTo, hasMany} from 'coalesce-ember/model/model'`
`import {setupApp, teardownApp} from './support/app'`

describe 'Session', ->

  beforeEach ->
    setupApp.apply(this)
    #each of our tests gets a model
    class @Post extends Model
      title: attr 'string'

    @Post.typeKey = 'post'

    @PostSerializer = Coalesce.ModelSerializer.extend
      typeKey: 'post'

    @container.register 'model:post', @Post
    @container.register 'serializer:post', @PostSerializer
    
  afterEach ->
    teardownApp.apply(this)
  
      
  describe '.isDirty', ->
    
    it 'is true when model is dirty', ->
      post = @session.merge @Post.create(title: 'sup', id: "1")
      expect(@session.isDirty).to.be.false
      post.title = 'bro'
      expect(@session.isDirty).to.be.true

  describe '.query', ->

    beforeEach ->
      @server.respondWith "GET", "/posts", (xhr, url) ->
        posts = [{id: 1, title:"title1", client_rev: 1, client_id: "post2"}]

        xhr.respond 200, { "Content-Type": "application/json" }, JSON.stringify({posts: posts})

    it 'should be a PromiseArray', ->
      postPromiseArray = @session.query('post')
      expect(postPromiseArray).to.be.an.instanceOf(PromiseArray)

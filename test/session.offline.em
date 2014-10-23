`import Model from 'coalesce-ember/model/model'`
`import {attr, belongsTo, hasMany} from 'coalesce-ember/model/model'`
`import {setupApp, teardownApp} from './support/app'`

describe 'Offline Session', ->

  session = null
  App = null

  beforeEach ->
    setupApp.apply(this)
    App = @App
    true
    
  afterEach ->
    teardownApp.apply(this)
      
  describe 'flushing', ->
    beforeEach ->
      class @Post extends Model
        title: attr 'string'
      @Post.typeKey = 'post'
      @container.register 'model:post', @Post

    it 'should contain/persist newModels on failure', ->
      post = @session.create 'post',
        title: 'post1'

      post2 = @session.create 'post',
        title: 'post2' 

      session = @session

      # CH: in our todo use case the sucess function is called rather than the fail in this case. 
      # but I think either way should be solved
      @session.flush().then null, ->
        expect(session.newModels.size).to.eq(2)

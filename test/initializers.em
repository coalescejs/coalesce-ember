`import setupApp from './support/setup_app'`

describe 'initializers', ->

  beforeEach ->
    setupApp.apply(this)
      
  it 'should setup container', ->
    expect(@container.lookup('session:main')).to.not.be.null
    
  it 'should perform type injections', ->
    visit '/'
    expect(@container.lookup('controller:application').session).to.not.be.null
    

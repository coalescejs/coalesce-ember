`import HasManyArray from 'coalesce-ember/collections/has_many_array'`
`import Model from 'coalesce-ember/model/model'`
`import {attr, belongsTo, hasMany} from 'coalesce-ember/model/model'`

describe 'HasManyArray', ->

  describe '.findProperty', ->
  
    beforeEach ->
      class @Post extends Model
        title: attr 'string'
  
    it 'works', ->
      arr = new HasManyArray()
      
      arr.pushObject(@Post.create(id: "1", title: 'test'))
      arr.pushObject(@Post.create(id: "2", title: 'nope'))
      
      expect(arr.findProperty('id', '1')).to.eql(arr.firstObject)
      

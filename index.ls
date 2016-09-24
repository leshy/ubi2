require! {
  xmlrpc
  lodash: { map, keys, mapValues }
  bluebird: p
  events: { EventEmitter }
}



class Node extends EventEmitter
  (opts) ->
    if not opts.name then throw "I didn't get a name"
    if not opts.parent then throw "I didn't get a parent"
    if not opts.style then opts.style = "default"
    @ <<< opts
    @connections = 0
    
  render: ->
    @parent.ubi 'new_vertex'
    .then (nodeId) ~>
      @id = nodeId
      @parent.ubi 'change_vertex_style', nodeId, @parent.style[ @style or "default" ]
      .then ~> @parent.ubi 'set_vertex_attribute', nodeId,'label', String @name
      .then ~> @parent.nodes[ @name ] = @
          
  connect: (node, style="default") ->
    if node?@@ is String then node = @parent.nodes[ node ]
    
    @parent.ubi 'new_edge', @id, node.id
    .then (edgeId) ~> @parent.ubi 'change_edge_style', edgeId, @parent.edgeStyle[style]
    .then ~>
      @listenConnection node
      node.listenConnection @

  listenConnection: (node) ->
    @connections += 1
    node.once 'remove', ~>
      console.log @name, @connections
      @connections -= 1
      if not @connections then @remove()
    

  
  remove: -> 
    @parent.ubi 'remove_vertex', @id
    .then ~> @emit 'remove'

  addChild: (opts) ->
    @parent.addNode(opts).then (child) ~>
      @connect child
  
module.exports = class ubigraph
  ->
    @style = {}
    @edgeStyle = {}
    @lineStyles = {}
    @nodes = {}
    
    @client = xmlrpc.createClient host: 'localhost', port: 20738, path: '/RPC2'
    
  start: ->

    defaultStyle = do
      shape: 'dodecahedron'
      size: '1.0'
      fontcolor: '#AFAFAF'
      fontfamily: 'Terminus'
      fontsize: '12'
      color: '#405c71'

    defaultEdgeStyle = do
      spline: "true"
      color: "#778877"
#      visible: "false"
#      arrow: "true"
#      arrow_radius: "0.4"
#      arrow_length: "2.0"
      strength: "0.01"
      fontfamily: "Fixed"
      
    @ubi 'clear'
    .then ~> @addStyle "default", defaultStyle
    .then ~> @addEdgeStyle "default", defaultEdgeStyle

  node: (opts) ->
    n = new Node (parent: @) <<< opts
    n.render()

  ubi: (method,...args) -> new p (resolve,reject) ~>
    console.log "CALL",method, args
    @client.methodCall "ubigraph.#{ method }", args, (err,data) ->
      if err then reject err else resolve data

  addStyle: (name, style) ~>
    @ubi 'new_vertex_style', (@style.default or 0)
    .then (id) ~>
      p.props mapValues style, (value, key) ~> @ubi 'set_vertex_style_attribute', id, key, value
      .then ~> @style[ name ] = id

  addEdgeStyle: (name, style) ~>
    styleId = keys(@edgeStyle).length
    @ubi 'new_edge_style', styleId
    .then (ubiStyleId) ~>
      p.props mapValues style, (value, key) ~> @ubi 'set_edge_style_attribute', styleId, key, value
    .then ~> @edgeStyle[ name ] = styleId

  addNode: (name,style="default") ->
    @node name: name, style: style
    
  delNode: (name) ->
    @nodes[ name ].remove()
    .then ~> delete @nodes[ name ]

#  connect: (name1,name2,style="default") ->
    

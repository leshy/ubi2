require! {
  xmlrpc
  lodash: { map, keys, mapValues, assign, values }
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
      .then ~> @parent.ubi 'set_vertex_attribute', nodeId,'label', String (@label or @name)
      .then ~> @parent.nodes[ @name ] = @

  changeStyle: ->
    @parent.ubi 'change_vertex_style', @id, @parent.style[ @style or "default" ]
    .then ~> @parent.ubi 'set_vertex_attribute', @id,'label', String (@label or @name)
                              
  connect: (node, style="default") ->
    if node?@@ is String then node = @parent.nodes[ node ]
    
    @parent.ubi 'new_edge', @id, node.id
    .then (edgeId) ~> @parent.ubi 'change_edge_style', edgeId, @parent.edgeStyle[style]
  #   .then ~>
  #     @listenConnection node
  #     node.listenConnection @

  # listenConnection: (node) ->
  #   @connections += 1
  #   node.once 'remove', ~>
  #     console.log @name, @connections
  #     @connections -= 1
  #     if not @connections then @remove()
  
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
    styles = do
      node:
        default:
          shape: 'dodecahedron'
          size: '1.0'
          fontcolor: '#AFAFAF'
          fontfamily: 'Terminus'
          fontsize: '12'
          color: '#405c71'
          
        green:
          color: '#467140'
          
        red:
          color: '#931416'

      edge:
      
        default:
          spline: "true"
          color: "#778877"
          strength: "0.1"
          fontfamily: "Fixed"
        
        red:
          spline: "false"
          strength: "0.001"
          color: "#931416"
          
        gray:
          spline: "false"
          strength: "0.001"
          color: "#5E5E5E"

    @ubi 'clear'
    .then ~>
      p.mapSeries map(styles.node, (style, name) ~> ~> @addStyle name, style), -> it()
    .then ~>
      p.mapSeries map(styles.edge, (style, name) ~> ~> @addEdgeStyle name, style), -> it()

  node: (opts) ->
    if node = @nodes[ opts.name ] then return new p (resolve,reject) ~> resolve assign node, opts
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
    @ubi 'new_edge_style', (@edgeStyle.default or 0)
    .then (id) ~>
      p.props mapValues style, (value, key) ~> @ubi 'set_edge_style_attribute', id, key, value
      .then ~> @edgeStyle[ name ] = id

  addNode: (name,style="default") ->
    @node name: name, style: style
    
  delNode: (name) ->
    @nodes[ name ].remove()
    .then ~> delete @nodes[ name ]

#  connect: (name1,name2,style="default") ->
    

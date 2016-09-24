require! {
  xmlrpc
  lodash: { map, keys, mapValues }
  bluebird: p
}


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
      fontcolor: '#ffffff'
      fontfamily: 'Terminus'
      fontsize: '12'
      color: '#405c71'

    defaultEdgeStyle = do
#      spline: "true"
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

  addNode: (name,style="default") -> new p (resolve,reject) ~> 
    @ubi 'new_vertex'
    .then (nodeId) ~>
      @nodes[ name ] = nodeId
      @ubi 'change_vertex_style',nodeId, @style[ style ]
      .then ~>
        resolve nodeId
        @ubi 'set_vertex_attribute', nodeId,'label', String name

  delNode: (name) ->
    @ubi 'del_vertex', @nodes[ name ]
    .then ~> delete @nodes[ name ]

  connect: (name1,name2,style="default") ->
    @ubi 'new_edge', @nodes[ name1 ], @nodes[ name2 ]
    .then (edgeId) ~>
      @ubi 'change_edge_style', edgeId, @edgeStyle[ style ]
    

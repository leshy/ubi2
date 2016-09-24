require! {
  xmlrpc
  lodash: { map }
  bluebird: p
}


export class ubigraph
  ->
    @client = xmlrpc.createClient host: 'localhost', port: 20738, path: '/RPC2'
    
  ubi: (method,...args) -> new p (resolve,reject) ~>
    client.methodCall "ubigraph.#{ method }", args, (err,data) ->
      if err then reject err else resolve data


  init: -> new p (resolve,reject) ~>

    vertexStyle: ~> 
      @ubi 'new_vertex_style', 0
      .then ~>
        p.all do
          @ubi 'set_vertex_style_attribute', 0,'shape','dodecahedron'
          @ubi 'set_vertex_style_attribute', 0,'size','1.0'
          @ubi 'set_vertex_style_attribute', 0,'fontcolor','#809c21'
          @ubi 'set_vertex_style_attribute', 0,'fontfamily','Fixed'
          @ubi 'set_vertex_style_attribute', 0,'fontsize','13'
          @ubi 'set_vertex_style_attribute', 0,'color','#405c71'


    edgeStyle: ~> new p (resolve,reject) ~> 
      resolve!

  addNode: (name) ->
    ubi 'new_vertex'
    .then (nodeId) ~>
      @nodes[ name ] = nodeId
      @ubi 'set_vertex_attribute', nodeId,'label',h.capitalize(name)

  connect: (name1,name2) ->
    @ubi 'new_edge',  @nodes[ name1 ], @nodes[ name2 ]
    

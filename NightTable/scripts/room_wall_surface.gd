extends RefCounted
## Cut the authored wall into doorway panels without stretching its original UVs.
static func clip_polygon(poly: Array, axis: int, boundary: float, sign_value: float) -> Array:
	var result: Array = []
	for i in poly.size():
		var a: Dictionary = poly[i]
		var b: Dictionary = poly[(i+1)%poly.size()]
		var da: float = (a.p[axis]-boundary)*sign_value
		var db: float = (b.p[axis]-boundary)*sign_value
		if da>=-0.00001: result.append(a)
		if (da>0 and db<0) or (da<0 and db>0):
			var t := da/(da-db)
			result.append({"p":a.p.lerp(b.p,t),"n":a.n.lerp(b.n,t).normalized(),"uv":a.uv.lerp(b.uv,t)})
	return result

static func apply(source: MeshInstance3D, panel: MeshInstance3D) -> void:
	# Panel bounds are in its local space; imported wall UVs remain untouched.
	var bounds := panel.get_aabb()
	var transform := panel.global_transform.affine_inverse()*source.global_transform
	var normal_transform := transform.basis.inverse().transposed()
	var output := ArrayMesh.new()
	for surface in source.mesh.get_surface_count():
		var arrays := source.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		var count := 0
		for triangle in range(0,indices.size(),3):
			var poly: Array = []
			for corner in 3:
				var index := indices[triangle+corner]
				poly.append({"p":transform*vertices[index],"n":(normal_transform*normals[index]).normalized(),"uv":uvs[index]})
			for axis in 3:
				poly=clip_polygon(poly,axis,bounds.position[axis],1)
				poly=clip_polygon(poly,axis,bounds.end[axis],-1)
			for k in range(1,poly.size()-1):
				for v in [poly[0],poly[k],poly[k+1]]:
					builder.set_normal(v.n)
					builder.set_uv(v.uv)
					builder.add_vertex(v.p)
					count+=1
		if count>0:
			builder.set_material(source.get_active_material(surface))
			builder.commit(output)
	panel.material_override=null
	panel.layers=source.layers
	panel.mesh=output

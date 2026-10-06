extends SceneTree
func _initialize():call_deferred("inspect")
func inspect():
	var route=CastleGenerator.ROUTE
	for spec in [route.bedroom,route.battle]+Array(route.events):
		var scene=load(spec.scene_path).instantiate()
		root.add_child(scene)
		var meshes=scene.find_children("*","MeshInstance3D",true,false)
		var triangles=0
		var surfaces=0
		var repeats={}
		for node in meshes:
			if not node.mesh:continue
			surfaces+=node.mesh.get_surface_count()
			for i in node.mesh.get_surface_count():
				if node.mesh is ArrayMesh:triangles+=node.mesh.surface_get_array_index_len(i)/3
			var key=node.mesh.get_instance_id()
			repeats[key]=repeats.get(key,0)+1
		var duplicate_instances=0
		for count in repeats.values():
			if count>1:duplicate_instances+=count-1
		var lights=scene.find_children("*","Light3D",true,false)
		var shadows=0
		for light in lights:
			if light.shadow_enabled:shadows+=1
		print("AUDIT ",spec.scene_path," meshes=",meshes.size()," surfaces=",surfaces," triangles=",triangles," repeated_meshes=",duplicate_instances," lights=",lights.size()," shadow_lights=",shadows)
		scene.free()
	quit()


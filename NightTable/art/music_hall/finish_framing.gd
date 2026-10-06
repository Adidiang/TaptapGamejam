extends SceneTree
func _initialize():call_deferred("build")
func build():
	var scene=load("res://art/music_hall/music_hall.tscn").instantiate()
	root.add_child(scene)
	# Current envelope runs from -12 to 0; extend it to +8 beneath the backed-up camera.
	var extension=Transform3D(Basis.from_scale(Vector3(20.0/12.0,1,1)),Vector3(8,0,0))
	for n in scene.get_node("Layout").get_children():
		if n is MeshInstance3D:
			if str(n.name) in ["立方体","立方体_001","立方体_003","立方体_004"]:n.global_transform=extension*n.global_transform
			if str(n.name).begins_with("huitugou_7106"):
				for i in n.mesh.get_surface_count():
					var m=n.get_active_material(i).duplicate()
					m.roughness_texture=null
					m.roughness=.7
					m.metallic_specular=.15
					n.set_surface_override_material(i,m)
	var packed=PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,"res://art/music_hall/music_hall.tscn")==OK)
	quit()

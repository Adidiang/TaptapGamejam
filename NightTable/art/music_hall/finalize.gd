extends SceneTree
func _initialize():call_deferred("build")
func build():
	var scene=load("res://art/music_hall/music_hall.tscn").instantiate()
	# Consolidate whole-mesh and per-surface overrides before the nodes enter rendering.
	for n in scene.get_node("MusicSalon").get_children():
		if n is MeshInstance3D and n.material_override:
			var mat=n.material_override
			n.mesh=n.mesh.duplicate()
			for i in n.mesh.get_surface_count():
				n.mesh.surface_set_material(i,mat)
				n.set_surface_override_material(i,null)
			n.material_override=null
	var packed=PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,"res://art/music_hall/music_hall.tscn")==OK)
	scene.free()
	quit()

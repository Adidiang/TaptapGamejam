extends SceneTree
func _initialize():call_deferred("build")
func build():
	var scene=load("res://art/music_hall/music_hall.tscn").instantiate()
	root.add_child(scene)
	for n in scene.get_node("MusicSalon").get_children():
		if not n is MeshInstance3D:continue
		var name=str(n.name)
		if name.begins_with("StageRearPanelling"):n.rotate_y(PI)
		if name.begins_with("StageRearPanelling") or name.begins_with("CarvedWallPanel") or name.begins_with("ArchitecturalColumn") or name.begins_with("RearPilaster"):
			var m=StandardMaterial3D.new()
			m.albedo_color=Color("425b55") if "Panel" in name else Color("887554")
			m.roughness=.8
			n.material_override=m
		if "Candelabra" in name or "Chandelier" in name or "Portrait" in name:
			for i in n.mesh.get_surface_count():
				var m=n.get_active_material(i).duplicate()
				m.albedo_color=Color("a99976")
				n.set_surface_override_material(i,m)
	var packed=PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,"res://art/music_hall/music_hall.tscn")==OK)
	quit()

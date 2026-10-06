extends SceneTree
func _initialize():call_deferred("build")
func build():
	var scene=load("res://art/music_hall/music_hall.tscn").instantiate()
	root.add_child(scene)
	var group=scene.get_node("SalonDetails")
	var ledge_mat=StandardMaterial3D.new()
	ledge_mat.albedo_color=Color("665b46")
	ledge_mat.roughness=.85
	for n in group.get_children():
		var name=str(n.name)
		if name.begins_with("UpperBalconyCorbel"):
			# Replace a poorly fitting concave bracket with a solid wall shelf.
			n.visible=false
			var shelf=MeshInstance3D.new()
			shelf.name="SculptureGalleryShelf"
			shelf.mesh=BoxMesh.new()
			shelf.mesh.size=Vector3(.9,.18,2.4)
			shelf.mesh.material=ledge_mat
			group.add_child(shelf,true)
			shelf.owner=scene
			shelf.position=Vector3(signf(n.position.x)*6.95,5.6,n.position.z)
		if name.begins_with("UpperBust") or name.begins_with("UpperStoneUrn"):n.position.y-=1.36
		if name.begins_with("FrontGiltConsole") or name.begins_with("ConsoleFlowers") or name.begins_with("ConsoleBooks"):
			n.position.z-=.95
			n.position.x-=signf(n.position.x)*.3
		if name.begins_with("StageBackdropPainting") or name.begins_with("CrystalPendant"):
			for i in n.mesh.get_surface_count():
				var m=n.get_active_material(i).duplicate()
				m.albedo_color=Color("b5a17b")
				n.set_surface_override_material(i,m)
	var packed=PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,"res://art/music_hall/music_hall.tscn")==OK)
	quit()

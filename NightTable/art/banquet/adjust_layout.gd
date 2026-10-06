extends SceneTree
func _initialize(): call_deferred("adjust")
func adjust():
	var room=load("res://art/banquet/banquet.tscn").instantiate()
	root.add_child(room)
	assert(not room.has_meta("layout_adjusted_oct04"),"Layout adjustment already applied")
	for node in room.get_node("Layout").get_children():
		if node.name.begins_with("tripo_node_e84aa062"):
			# Native X is the hall's depth; keep width, height and table centers.
			var t=node.transform
			t.basis=Basis.from_scale(Vector3(0.8,1,1))*t.basis
			node.transform=t
		if node.name.begins_with("Obj3d66-18249362"):
			node.position.x-=0.9
	for camera in room.find_children("*","Camera3D",true,false):
		camera.basis=Basis(Vector3.UP,PI/2)*Basis(Vector3.RIGHT,deg_to_rad(-7.0))
	room.set_meta("layout_adjusted_oct04",true)
	var packed=PackedScene.new()
	assert(packed.pack(room)==OK)
	assert(ResourceSaver.save(packed,"res://art/banquet/banquet.tscn")==OK)
	print("LAYOUT_ADJUSTED: depth 80%, doors back 0.9m, camera pitch 7 degrees")
	quit()

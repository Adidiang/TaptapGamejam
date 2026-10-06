extends SceneTree
func _initialize():
	call_deferred("inspect")
func inspect():
	var wrapper := Node3D.new()
	root.add_child(wrapper)
	wrapper.rotation_degrees.y = -90
	var room = load("res://art/bedroom_v2/bedroom.tscn").instantiate()
	wrapper.add_child(room)
	for mesh in room.find_children("*","MeshInstance3D",true,false):
		print(mesh.name," ",mesh.global_transform*mesh.get_aabb())
	wrapper.free()
	quit()

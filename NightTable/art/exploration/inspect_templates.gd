extends SceneTree
func _initialize():call_deferred("inspect")
func inspect():
	for id in ["armory","cellar","auditorium","palace","music_hall"]:
		var s=load("res://art/%s/%s.tscn"%[id,id]).instantiate()
		root.add_child(s)
		print("ROOM ",id)
		for n in s.find_children("*","Node3D",true,false):
			if n is Camera3D:print("CAM ",s.get_path_to(n)," ",n.global_position," rot ",n.global_rotation_degrees," fov ",n.fov)
			if n is MeshInstance3D and ("Door" in str(n.name) or "883" in str(n.name) or "立方体" in str(n.name) or "Floor" in str(n.name)):
				print("MESH ",s.get_path_to(n)," ",n.global_transform*n.mesh.get_aabb())
		s.free()
	quit()

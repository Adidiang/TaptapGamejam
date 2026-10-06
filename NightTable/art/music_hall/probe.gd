extends SceneTree
func _initialize(): call_deferred("probe")
func probe():
	var s=load("res://art/music_hall/music_hall.tscn").instantiate()
	root.add_child(s)
	for m in s.get_node("Layout").find_children("*","MeshInstance3D",true,false): print(m.name," ",m.global_transform*m.mesh.get_aabb())
	quit()


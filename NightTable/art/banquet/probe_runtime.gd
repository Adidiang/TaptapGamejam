extends SceneTree
func _initialize(): call_deferred("probe")
func probe():
	var n=load("res://art/banquet/banquet.tscn").instantiate()
	root.add_child(n)
	n.rotation.y=-PI/2
	for m in n.find_children("*","MeshInstance3D",true,false):
		var b=m.global_transform*m.get_aabb()
		if m.get_parent().name=="Layout" or (b.size.y>0.65 and b.position.y<0.4): print(m.get_path()," ",b)
	for c in n.find_children("*","Camera3D",true,false): print("CAMERA ",c.get_path()," ",c.global_position," ",c.global_rotation_degrees)
	quit()

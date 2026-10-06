extends SceneTree
func _initialize(): call_deferred("finish")
func finish():
	var room=load("res://art/cellar/cellar.tscn").instantiate()
	root.add_child(room)
	for node in room.get_node("Architecture").get_children():
		if str(node.name).begins_with("RearStone") or str(node.name).begins_with("RearMortar"): node.position.z+=1.05
	for section in ["SmallProps","BottlesAndVessels"]:
		for node in room.get_node(section).get_children():
			if node is MeshInstance3D:
				var b: AABB=node.transform*node.get_aabb()
				if b.get_center().z>2.1: node.position.z-=.85
	room.get_node("Lighting/ForegroundAmber").light_energy=4.2
	room.get_node("Lighting/RightBottleRose").light_energy=2.7
	var packed=PackedScene.new()
	assert(packed.pack(room)==OK)
	assert(ResourceSaver.save(packed,"res://art/cellar/cellar.tscn")==OK)
	room.queue_free()
	await process_frame
	quit()

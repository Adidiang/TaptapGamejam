extends SceneTree
func _initialize():call_deferred("build")
func build():
	var scene=load("res://art/music_hall/music_hall.tscn").instantiate()
	root.add_child(scene)
	# Native X is room depth; preserve width, height and the rear-wall position.
	var depth=Transform3D(Basis.from_scale(Vector3(.8,1,1)),Vector3(-2.4,0,0))
	for n in scene.get_node("Layout").get_children():
		if n is MeshInstance3D:
			var t=n.global_transform
			if str(n.name).begins_with("立方体") or str(n.name).begins_with("tripo_node_80993"):
				n.global_transform=depth*t
			else:
				t.origin=depth*t.origin
				n.global_transform=t
	for n in scene.get_node("MusicSalon").get_children():
		if n is Node3D:
			var t=n.global_transform
			t.origin=depth*t.origin
			n.global_transform=t
	# Furniture and panels nearest the doors must not cover the entrances.
	for n in scene.get_node("MusicSalon").get_children():
		var name=str(n.name)
		if name.begins_with("ForwardLibrary"):
			n.position.z=-8.7
			n.position.x=signf(n.position.x)*6.8
		if name.begins_with("LibraryVolumes") and n.position.z>-2.1:
			n.position.z-=7.7
		if name.begins_with("CarvedWallPanel") and n.position.z>-2.0:n.visible=false
		if name.begins_with("CornerPlant") and n.position.z>-1:n.position.z=-5.4
	for n in scene.get_children():
		if n is Light3D:n.position.x=n.position.x*.8-2.4
	var cameras=scene.get_node("Layout").find_children("*","Camera3D",true,false)
	for camera in cameras:camera.position.x+=1.8
	scene.get_node("PreviewCamera").global_transform=cameras[0].global_transform.interpolate_with(cameras[1].global_transform,.5)
	var packed=PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,"res://art/music_hall/music_hall.tscn")==OK)
	print("DOOR_FRAMING_SAVED")
	quit()

extends SceneTree
func _initialize(): call_deferred("build")
func box(parent,label,dimensions,pos,material,owner_node):
	var mesh=MeshInstance3D.new()
	mesh.name=label
	mesh.mesh=BoxMesh.new()
	mesh.mesh.size=dimensions
	mesh.material_override=material
	parent.add_child(mesh)
	mesh.position=pos
	mesh.owner=owner_node
func build():
	var source=load("res://art/banquet/banquet.tscn").instantiate()
	root.add_child(source)
	var bedroom=load("res://art/bedroom_v2/bedroom.tscn").instantiate()
	source.get_node("PreviewEnvironment").environment=bedroom.get_node("PreviewEnvironment").environment.duplicate()
	bedroom.free()
	if not source.has_node("DreamGrade"):
		var grade=load("res://art/exploration/room_paper_filter.tscn").instantiate()
		source.add_child(grade)
		grade.owner=source
	for mesh in source.find_children("*","MeshInstance3D",true,false):
		for i in mesh.mesh.get_surface_count():
			var m=mesh.get_active_material(i)
			if m is StandardMaterial3D:
				m=m.duplicate()
				m.metallic=0
				m.metallic_specular=0
				m.roughness=1
				m.normal_enabled=false
				mesh.set_surface_override_material(i,m)
	var saved=PackedScene.new()
	assert(saved.pack(source)==OK)
	assert(ResourceSaver.save(saved,"res://art/banquet/banquet.tscn")==OK)
	source.free()
	var wrapper=Node3D.new()
	wrapper.name="BanquetRoom"
	wrapper.set_script(load("res://scripts/exploration_room.gd"))
	root.add_child(wrapper)
	source=saved.instantiate()
	source.name="Banquet"
	wrapper.add_child(source)
	source.owner=wrapper
	source.scene_file_path="res://art/banquet/banquet.tscn"
	source.rotation.y=-PI/2
	var spec=ExplorationRoomDefinition.new()
	spec.scene_path="res://art/exploration/banquet_room.tscn"
	# Align the authored door centers with the existing route; move the whole room,
	# never shift the user's doors relative to furniture.
	var leaf=source.get_node("Layout/Obj3d66-18249362-93-883")
	var b: AABB=leaf.global_transform*leaf.get_aabb()
	source.position.z=-1.346-b.get_center().z
	var offset=source.position.z
	spec.floor_bounds=Rect2(-4.5,-9.5+offset,9,12.5)
	spec.spawn=Vector2(-3.85,-1.346)
	spec.interaction=Vector2(0,-1.346)
	spec.camera_pitch=-7
	spec.camera_left_anchor=NodePath("Banquet/Layout/摄像机")
	spec.camera_right_anchor=NodePath("Banquet/Layout/摄像机_001")
	spec.camera_position=source.get_node("Layout/摄像机_001").global_position
	for mesh in source.find_children("*","MeshInstance3D",true,false):
		if mesh.name.begins_with("立方体") or mesh.name.begins_with("Obj3d66"): continue
		var bounds: AABB=mesh.global_transform*mesh.get_aabb()
		if bounds.position.y<0.4 and bounds.size.y>0.65:
			spec.obstacles.append(Rect2(bounds.position.x,bounds.position.z,bounds.size.x,bounds.size.z))
	assert(ResourceSaver.save(spec,"res://art/exploration/banquet_definition.tres")==OK)
	wrapper.definition=spec
	for direction in [-1,1]:
		var door=Node3D.new()
		door.name="LeftDoor" if direction<0 else "RightDoor"
		wrapper.add_child(door)
		door.owner=wrapper
		door.position=Vector3(direction*4.5,0.1,-1.346)
		var hinge=Node3D.new()
		hinge.name="Hinge"
		door.add_child(hinge)
		hinge.position.z=-spec.door_width/2
		hinge.owner=wrapper
		var wall=source.get_node("Layout/立方体_003" if direction<0 else "Layout/立方体_004")
		var material=wall.get_active_material(0)
		var start=-12+offset
		var end=3+offset
		var rear=-1.346-spec.door_width/2
		var front=-1.346+spec.door_width/2
		box(wrapper,door.name+"BackWall",Vector3(.1,6,rear-start),Vector3(direction*4.55,3,(rear+start)/2),material,wrapper)
		box(wrapper,door.name+"FrontWall",Vector3(.1,6,end-front),Vector3(direction*4.55,3,(front+end)/2),material,wrapper)
		box(wrapper,door.name+"Lintel",Vector3(.1,3.4,spec.door_width),Vector3(direction*4.55,4.3,-1.346),material,wrapper)
	var packed=PackedScene.new()
	assert(packed.pack(wrapper)==OK)
	assert(ResourceSaver.save(packed,"res://art/exploration/banquet_room.tscn")==OK)
	print("BANQUET_INTEGRATED offset=",offset," obstacles=",spec.obstacles.size())
	quit()

extends SceneTree
func _initialize():call_deferred("build")
func build():
	var catalog={
		"armory":["兵器库",.9,0.0,.7,0.0,-3.5,3.5,"LeftDoor/DoorHinge/EditableDoorLeaf","RightDoor/DoorHinge/EditableDoorLeaf"],
		"cellar":["酒窖",1.0,0.0,-.3,0.0,-7.0,5.0,"",""],
		"auditorium":["礼堂",.6,-90.0,.159855,0.06,-12.0,3.0,"Layout/Obj3d66-18249362-93-883_001","Layout/Obj3d66-18249362-93-883_002"],
		"palace":["寝宫",1.0,-90.0,1.743605,.1,-3.4176,3.0,"Layout/Obj3d66-18249362-93-883_001","Layout/Obj3d66-18249362-93-883"],
		"music_hall":["音乐厅",.6,-90.0,-2.272116,.06,-12.0,4.0,"Layout/Obj3d66-18249362-93-883_001","Layout/Obj3d66-18249362-93-883_002"]}
	for id in catalog:
		var p=catalog[id]
		var spec=ExplorationRoomDefinition.new()
		spec.display_name=p[0]
		spec.scene_path="res://art/exploration/"+id+"_room.tscn"
		var offset=-1.346-float(p[3])*float(p[1])
		spec.floor_y=p[4]
		spec.floor_bounds=Rect2(-4.5,float(p[5])*float(p[1])+offset,9,(float(p[6])-float(p[5]))*float(p[1]))
		spec.spawn=Vector2(0,-1.346)
		spec.interaction=Vector2(0,-1.346)
		spec.door_width=1.227*float(p[1]) if float(p[2])<0 else 1.227
		var wrapper=Node3D.new()
		wrapper.name=id.to_pascal_case()+"Room"
		wrapper.set_script(load("res://scripts/authored_room.gd"))
		wrapper.definition=spec
		wrapper.left_leaf=NodePath(p[7])
		wrapper.right_leaf=NodePath(p[8])
		wrapper.unit_scale=p[1]
		var art=load("res://art/%s/%s.tscn"%[id,id]).instantiate()
		art.name="Art"
		wrapper.add_child(art)
		art.owner=wrapper
		art.rotation_degrees.y=p[2]
		art.scale=Vector3.ONE*float(p[1])
		art.position.z=offset
		# Use a holder to avoid standalone-preview _ready behavior while measuring.
		var holder=Node3D.new()
		root.add_child(holder)
		holder.add_child(wrapper)
		var cameras=art.find_children("*","Camera3D",true,false)
		cameras.sort_custom(func(a,b):return a.global_position.x<b.global_position.x)
		spec.camera_left_anchor=wrapper.get_path_to(cameras.front())
		spec.camera_right_anchor=wrapper.get_path_to(cameras.back())
		spec.camera_position=(cameras.front().global_position+cameras.back().global_position)*.5
		spec.camera_pitch=cameras.front().global_rotation_degrees.x
		spec.camera_fov=cameras.front().fov
		for mesh in art.find_children("*","MeshInstance3D",true,false):
			if not mesh.is_visible_in_tree():continue
			var b: AABB=mesh.global_transform*mesh.mesh.get_aabb()
			if b.size.y<.28 or b.position.y>spec.floor_y+1.0:continue
			if b.size.x>8.0 or b.size.z>12.0:continue
			var obstacle=Rect2(b.position.x,b.position.z,b.size.x,b.size.z).intersection(spec.floor_bounds)
			if obstacle.size.x<.05 or obstacle.size.y<.05:continue
			# The transverse entry aisle is intentionally kept navigable.
			if obstacle.end.y< -1.346-.5 or obstacle.position.y> -1.346+.5:spec.obstacles.append(obstacle)
		assert(ResourceSaver.save(spec,"res://art/exploration/"+id+"_definition.tres")==OK)
		var packed=PackedScene.new()
		assert(packed.pack(wrapper)==OK)
		assert(ResourceSaver.save(packed,spec.scene_path)==OK)
		print("ADAPTER ",id," cameras ",spec.camera_position," pitch ",spec.camera_pitch)
		holder.free()
	quit()

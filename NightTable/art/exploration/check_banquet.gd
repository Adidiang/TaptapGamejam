extends SceneTree
func _initialize(): call_deferred("check_room")
func settle(view):
	for i in range(150): view._process(1.0/60.0)
	for i in range(6): await process_frame
func shot(name):
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("F:/gamejam/outputs/banquet")
	root.get_texture().get_image().save_png("F:/gamejam/outputs/banquet/"+name+".png")
func check_room():
	root.size=Vector2i(1600,900)
	var state=CastleExploration.new()
	state.start(217,true)
	assert(state.layout.rooms[1].definition.scene_path.ends_with("banquet_room.tscn"))
	var view=CastleView.new()
	view.configure(state)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(view)
	view.focused=false
	view.set_process(false)
	await process_frame
	var art=view.room_visuals[1].art
	assert(art.has_node("Banquet/DiningDecor"))
	assert(art.find_children("DreamGrade","CanvasLayer",true,false).is_empty())
	# Doorway panels must use the current authored wallpaper, with preserved UVs.
	for side in ["Left","Right"]:
		var source_wall=art.get_node("Banquet/Layout/立方体_003" if side=="Left" else "Banquet/Layout/立方体_004")
		assert(source_wall.get_active_material(0).albedo_texture!=null)
		for part in ["BackWall","FrontWall","Lintel"]:
			var panel=art.get_node(side+"Door"+part)
			assert(panel.mesh.get_surface_count()>0)
			assert(panel.get_active_material(0)==source_wall.get_active_material(0))
			assert(panel.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV].size()>0)
	assert(art.get_node("Banquet/Layout/立方体").get_active_material(0).albedo_texture!=null)
	for direction in [-1,1]:
		var d=art.get_node("LeftDoor" if direction<0 else "RightDoor")
		assert(is_equal_approx(d.position.z,state.layout.rooms[1].definition.door(direction).y))
		var leaves=d.get_node("Hinge").get_children()
		assert(leaves.size()==1)
	assert(is_equal_approx(state.layout.rooms[0].definition.right_door.y,state.layout.rooms[1].definition.left_door.y))
	state.move(0,state.definition().right_door.y-state.player_z)
	state.move(3.85)
	view._sync()
	view._snap_camera()
	var before=view.camera.position
	state.move(1)
	assert(state.current==1)
	view._sync()
	assert(view.camera.position.is_equal_approx(before))
	assert(view.room_visuals[0].node.visible)
	await settle(view)
	assert(view.camera.position.distance_to(view._camera_target())<.03)
	state.move(-state.local_position().x)
	view._sync()
	await settle(view)
	await shot("in_game")
	assert(state.locked())
	state.room().cleared=true
	state.move(5)
	assert(state.current==2)
	view._sync()
	await settle(view)
	await shot("next_room")
	state.move(-1)
	assert(state.current==1)
	state.move(-10)
	assert(state.current==0)
	print("BANQUET_OK: aligned doors, original layout, one filter, smooth camera, bidirectional route")
	quit()

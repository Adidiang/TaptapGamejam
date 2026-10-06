extends SceneTree
func _initialize(): call_deferred("capture")
func capture():
	root.size = Vector2i(1600,900)
	root.content_scale_size = Vector2i.ZERO
	var state := CastleExploration.new()
	state.start(217,true)
	var view := CastleView.new()
	view.configure(state)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(view)
	view.focused = false
	var folder := "F:/gamejam/outputs/linear_rooms"
	DirAccess.make_dir_recursive_absolute(folder)
	for step in range(3):
		if step==1:
			state.move(0,state.definition().right_door.y-state.player_z)
			state.move(3.85)
		elif step==2:
			state.move(1.0)
			assert(state.current==1)
			state.move(-state.local_position().x)
			state.move(0,state.definition().interaction.y-state.player_z)
		view._sync()
		for frame in range(12): await process_frame
		await RenderingServer.frame_post_draw
		var path: String = folder+"/"+["bedroom","bedroom_door","whitebox"][step]+".png"
		assert(root.get_texture().get_image().save_png(path)==OK)
		print("CAPTURE_SAVED ",path)
	quit()

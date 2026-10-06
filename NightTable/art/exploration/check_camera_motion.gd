extends SceneTree

func _initialize(): call_deferred("check_motion")

func check_motion():
	root.size = Vector2i(1600,900)
	var state := CastleExploration.new()
	state.start(217,true)
	var view := CastleView.new()
	view.configure(state)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(view)
	view.focused = false
	await process_frame
	view.set_process(false)
	var bounds: Dictionary = view.room_visuals[0]
	assert(is_equal_approx(bounds.camera_left.x,0.037620068))
	assert(is_equal_approx(bounds.camera_right.x,1.0476923))
	var original_x := state.player_x
	state.player_x = -4.5
	assert(view._camera_target().is_equal_approx(bounds.camera_left))
	state.player_x = 4.5
	assert(view._camera_target().is_equal_approx(bounds.camera_right))
	state.player_x = original_x
	view._snap_camera()
	state.move(0,state.definition().right_door.y-state.player_z)
	state.move(3.85)
	view._sync()
	view._snap_camera()
	var before := view.camera.position
	state.move(1.0)
	assert(state.current==1)
	view._sync()
	assert(view.camera.position.is_equal_approx(before))
	assert(view.room_visuals[0].node.visible and view.room_visuals[1].node.visible)
	var target := view._camera_target()
	view._update_camera(1-exp(-4.5/60.0))
	assert(view.camera.position.distance_to(target)<before.distance_to(target))
	assert(view.camera.position.distance_to(before)<1.0)
	if "--capture" in OS.get_cmdline_user_args():
		for frame in range(12): view._process(1.0/60.0)
		for frame in range(5): await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("F:/gamejam/outputs/camera_motion")
		root.get_texture().get_image().save_png("F:/gamejam/outputs/camera_motion/transition.png")
	for frame in range(180): view._process(1.0/60.0)
	assert(view.outgoing_rooms.is_empty())
	view._sync()
	assert(not view.room_visuals[0].node.visible)
	assert(view.camera.position.distance_to(target)<0.025)
	print("CAMERA_MOTION_OK: authored endpoints, no teleport, smooth travel, outgoing room cleanup")
	quit()

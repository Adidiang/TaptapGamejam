extends SceneTree

func _initialize(): call_deferred("capture")

func capture():
	root.size=Vector2i(1920,1080)
	root.content_scale_size=Vector2i.ZERO
	root.msaa_3d=Viewport.MSAA_4X
	var room=load("res://art/palace/palace.tscn").instantiate()
	root.add_child(room)
	room.get_node("MiddleCamera").make_current()
	for frame in range(40): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("F:/gamejam/outputs/palace")
	assert(root.get_texture().get_image().save_png("F:/gamejam/outputs/palace/middle_camera.png")==OK)
	print("PALACE_CAPTURE_SAVED")
	if "--all-views" in OS.get_cmdline_user_args():
		for pair in [["摄像机_001","side_right"],["摄像机","side_left"]]:
			room.get_node("Layout/"+pair[0]).make_current()
			for frame in range(15):await process_frame
			await RenderingServer.frame_post_draw
			assert(root.get_texture().get_image().save_png("F:/gamejam/outputs/palace/"+pair[1]+".png")==OK)
		print("SIDE_VIEWS_SAVED")
	room.queue_free()
	await process_frame
	await process_frame
	quit()

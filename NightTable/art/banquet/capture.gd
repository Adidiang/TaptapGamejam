extends SceneTree
func _initialize(): call_deferred("capture")
func capture():
	root.size=Vector2i(1920,1080)
	root.content_scale_size=Vector2i.ZERO
	root.msaa_3d=Viewport.MSAA_4X
	var room=load("res://art/banquet/banquet.tscn").instantiate()
	root.add_child(room)
	var cameras=room.get_node("Layout").find_children("*","Camera3D",true,false)
	assert(cameras.size()==2)
	room.get_node("PreviewCamera").global_transform=cameras[0].global_transform.interpolate_with(cameras[1].global_transform,0.5)
	for frame in range(30): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("F:/gamejam/outputs/banquet")
	assert(root.get_texture().get_image().save_png("F:/gamejam/outputs/banquet/decorated_midpoint.png")==OK)
	print("BANQUET_CAPTURE_SAVED")
	quit()

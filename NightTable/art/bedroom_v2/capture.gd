extends SceneTree
func _initialize():
	call_deferred("capture")
func capture():
	root.size=Vector2i(1920,1080)
	root.content_scale_size=Vector2i.ZERO
	root.msaa_3d=Viewport.MSAA_4X
	root.add_child(load("res://art/bedroom_v2/bedroom.tscn").instantiate())
	for frame in range(20):await process_frame
	await RenderingServer.frame_post_draw
	var folder="F:/gamejam/outputs/bedroom_v2"
	DirAccess.make_dir_recursive_absolute(folder)
	assert(root.get_texture().get_image().save_png(folder+"/preview.png")==OK)
	print("CAPTURE_SAVED ",folder,"/preview.png")
	quit()

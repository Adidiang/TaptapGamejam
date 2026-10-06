extends SceneTree
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1920,1080)
	root.content_scale_size=Vector2i.ZERO
	root.msaa_3d=Viewport.MSAA_4X
	var scene=load("res://art/armory/armory.tscn").instantiate()
	root.add_child(scene)
	DirAccess.make_dir_recursive_absolute("F:/gamejam/outputs/armory")
	for pair in [["MiddleCamera","preview"],["CameraLeft","left"],["CameraRight","right"]]:
		scene.get_node("Cameras/"+pair[0]).make_current()
		for i in 30:await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("F:/gamejam/outputs/armory/"+pair[1]+".png")==OK)
	print("ARMORY_VIEWS_SAVED")
	scene.queue_free();await process_frame;await process_frame;quit()


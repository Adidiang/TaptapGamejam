extends SceneTree
func _initialize(): call_deferred("capture")
func capture():
	root.size=Vector2i(1920,1080)
	root.msaa_3d=Viewport.MSAA_4X
	var scene=load("res://art/cellar/cellar.tscn").instantiate()
	root.add_child(scene)
	scene.get_node("Cameras/PreviewCamera").global_transform=scene.get_node("Cameras/CameraLeft").global_transform.interpolate_with(scene.get_node("Cameras/CameraRight").global_transform,.5)
	for i in 40: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("F:/gamejam/outputs/cellar/preview.png")==OK)
	print("CELLAR_CAPTURE_OK")
	scene.queue_free()
	await process_frame
	await process_frame
	quit()

extends SceneTree

func _initialize():
	call_deferred("capture")

func capture():
	root.size = Vector2i(1920,1080)
	root.content_scale_size = Vector2i.ZERO
	root.msaa_3d = Viewport.MSAA_4X
	var room = load("res://art/bedroom_v2/bedroom.tscn").instantiate()
	root.add_child(room)
	var left: Camera3D = room.get_node("FurnitureAndArchitecture/摄像机2")
	var right: Camera3D = room.get_node("FurnitureAndArchitecture/摄像机")
	var camera: Camera3D = room.get_node("PreviewCamera")
	camera.global_transform = left.global_transform.interpolate_with(right.global_transform,0.5)
	camera.fov = lerpf(left.fov,right.fov,0.5)
	camera.make_current()
	for frame in range(30): await process_frame
	await RenderingServer.frame_post_draw
	var destination = "F:/gamejam/outputs/bedroom_v2/midpoint.png"
	DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
	assert(root.get_texture().get_image().save_png(destination)==OK)
	print("MIDPOINT_CAPTURE_SAVED ",destination," position=",camera.global_position)
	quit()

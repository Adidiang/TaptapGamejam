extends SceneTree
var names = ["battle_room","event_room","shop_room"]

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1440,1000)
	root.msaa_3d = Viewport.MSAA_4X
	for room_name in names:
		var scene = load("res://art/room_studies/"+room_name+".tscn").instantiate()
		root.add_child(scene)
		for i in range(12): await process_frame
		await RenderingServer.frame_post_draw
		var screenshot = root.get_texture().get_image()
		var path = "res://captures/room_studies/"+room_name+".png"
		assert(screenshot.save_png(path)==OK)
		print("CAPTURED ",path)
		root.remove_child(scene)
		scene.queue_free()
		await process_frame
	quit()

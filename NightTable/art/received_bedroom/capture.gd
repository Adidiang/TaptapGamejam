extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i.ZERO
	root.msaa_3d = Viewport.MSAA_4X
	var scene: Node3D = load("res://art/received_bedroom/bedroom.tscn").instantiate()
	root.add_child(scene)
	for frame in range(20):
		await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	assert(picture.get_width() == 1920 and picture.get_height() == 1080)
	var destination := "F:/gamejam/outputs/received_bedroom/卧室_Godot_梦核.png"
	DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
	assert(picture.save_png(destination) == OK)
	print("CAPTURE_SAVED ", destination)
	if "--lighting-study" in OS.get_cmdline_user_args():
		var lights := scene.find_children("Adapted_*", "Light3D", true, false)
		var energy: Array[float] = []
		for light in lights:
			energy.append(light.light_energy)
		var world := scene.get_node("BedroomEnvironment") as WorldEnvironment
		world.environment.ssao_enabled = true
		world.environment.ssao_radius = 0.5
		world.environment.ssao_intensity = 1.8
		for factor: float in [3.0, 6.0, 10.0]:
			for index in range(lights.size()):
				lights[index].light_energy = energy[index] * factor
			for frame in range(8):
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("F:/gamejam/outputs/received_bedroom/lighting_" + str(int(factor)) + ".png")
	if "--diagnose-shadows" in OS.get_cmdline_user_args():
		for light in scene.find_children("*", "Light3D", true, false):
			light.shadow_enabled = false
		for frame in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("F:/gamejam/outputs/received_bedroom/shadow_diagnostic.png")
	quit()

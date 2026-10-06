extends SceneTree

const DEST := "res://art/received_bedroom/"

func pose(rows: Array) -> Transform3D:
	return Transform3D(Basis(Vector3(rows[0][0], rows[1][0], rows[2][0]), Vector3(rows[0][1], rows[1][1], rows[2][1]), Vector3(rows[0][2], rows[1][2], rows[2][2])), Vector3(rows[0][3], rows[1][3], rows[2][3]))

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	var info: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DEST + "source_camera.json"))
	var room := Node3D.new()
	room.name = "ReceivedBedroom"
	room.set_script(load(DEST + "bedroom.gd"))
	root.add_child(room)
	var source: Node3D = load(DEST + "bedroom.glb").instantiate()
	source.name = "OriginalScene"
	room.add_child(source)
	source.owner = room
	for node in source.find_children("*", "Light3D", true, false):
		node.visible = false
	for node in source.find_children("*", "Camera3D", true, false):
		node.current = false
	var camera := Camera3D.new()
	camera.name = "OriginalCamera"
	camera.transform = pose(info.camera_transform)
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.fov = info.vertical_fov_degrees
	camera.near = maxf(0.03, info.near)
	camera.far = maxf(100.0, info.far)
	room.add_child(camera)
	camera.owner = room
	camera.current = true
	for data: Dictionary in info.lights:
		var light: Light3D
		if data.type == "AREA":
			var spot := SpotLight3D.new()
			spot.spot_range = 18.0
			spot.spot_angle = 85.0
			spot.spot_angle_attenuation = 0.5
			spot.spot_attenuation = 0.8
			light = spot
			light.light_energy = data.energy / 400.0 * 6.0
		else:
			var omni := OmniLight3D.new()
			omni.omni_range = 14.0
			omni.omni_attenuation = 1.0
			light = omni
			light.light_energy = data.energy / 180.0 * 6.0
		light.name = "Adapted_" + str(data.name)
		light.transform = pose(data.transform)
		light.light_color = Color(data.color[0], data.color[1], data.color[2])
		match str(data.name):
			"面光":
				light.light_color = Color(1.0, 0.86, 0.7)
				light.light_energy = 1.25
			"面光.001":
				light.light_color = Color(1.0, 0.59, 0.65)
				light.light_energy = 0.85
			"点光":
				light.light_color = Color(0.52, 0.85, 0.38)
				light.light_energy = 0.75
			"点光.001":
				light.light_color = Color(0.32, 0.82, 0.66)
				light.light_energy = 0.65
		light.shadow_enabled = true
		light.shadow_bias = 0.12
		light.shadow_normal_bias = 0.8
		light.light_size = 0.35
		room.add_child(light)
		light.owner = room
	var environment := WorldEnvironment.new()
	environment.name = "BedroomEnvironment"
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.075, 0.075, 0.09)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.78, 0.84, 0.65)
	environment.environment.ambient_light_energy = 0.24
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment.ssao_enabled = true
	environment.environment.ssao_radius = 0.5
	environment.environment.ssao_intensity = 1.8
	environment.environment.glow_enabled = true
	environment.environment.glow_intensity = 0.65
	environment.environment.glow_bloom = 0.12
	environment.environment.glow_hdr_threshold = 1.1
	environment.environment.fog_enabled = true
	environment.environment.fog_light_color = Color(0.62, 0.62, 0.5)
	environment.environment.fog_light_energy = 0.35
	environment.environment.fog_density = 0.005
	room.add_child(environment)
	environment.owner = room
	var tv_fill := OmniLight3D.new()
	tv_fill.name = "TV_MintBounce"
	tv_fill.position = Vector3(2.3, 1.6, 3.6)
	tv_fill.light_color = Color(0.4, 0.95, 0.68)
	tv_fill.light_energy = 0.65
	tv_fill.omni_range = 4.5
	tv_fill.omni_attenuation = 1.3
	room.add_child(tv_fill)
	tv_fill.owner = room
	var grade_layer := CanvasLayer.new()
	grade_layer.name = "DreamGrade"
	grade_layer.layer = 1
	room.add_child(grade_layer)
	grade_layer.owner = room
	var grade := ColorRect.new()
	grade.name = "DreamFilm"
	grade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var grade_material := ShaderMaterial.new()
	grade_material.shader = load(DEST + "dream_grade.gdshader")
	grade.material = grade_material
	grade_layer.add_child(grade)
	grade.owner = room
	var packed := PackedScene.new()
	assert(packed.pack(room) == OK)
	assert(ResourceSaver.save(packed, DEST + "bedroom.tscn") == OK)
	print("BEDROOM_SAVED camera_fov=", camera.fov, " meshes=", source.find_children("*", "MeshInstance3D", true, false).size())
	quit()

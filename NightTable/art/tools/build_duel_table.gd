extends SceneTree
var scene: Node3D

func _initialize() -> void:
	call_deferred("build")

func part(key: String,pos: Vector3,scale_value: Vector3,yaw: float = 0.0) -> void:
	var node := MeshInstance3D.new()
	node.name = key
	node.mesh = load("res://art/tavern_library/meshes/"+key+".res")
	scene.add_child(node,true)
	node.owner = scene
	node.position = pos
	node.scale = scale_value
	node.rotation_degrees.y = yaw

func build() -> void:
	DirAccess.make_dir_recursive_absolute("res://art/duel")
	scene = Node3D.new()
	scene.name = "DuelTable"
	scene.set_script(load("res://scripts/duel_table_art.gd"))
	part("table_rectangle_01",Vector3(0,-1.18,0),Vector3(8,1,3))
	part("candlestick_01",Vector3(-5.4,0,-3.0),Vector3.ONE*1.1)
	part("candlestick_02",Vector3(5.4,0,-3.0),Vector3.ONE*1.4)
	part("bookpile_01",Vector3(-4.3,0,1.0),Vector3.ONE*1.4,18)
	part("tankard_01",Vector3(4.4,0,0.5),Vector3.ONE*1.5)
	part("bottle_02",Vector3(3.9,0,-2.8),Vector3.ONE*1.5)
	for x in [-5.4,5.4]:
		var light := OmniLight3D.new()
		light.name = "CandleLeft" if x<0 else "CandleRight"
		light.position = Vector3(x,2.0,-3.0)
		light.light_color = Color("ffc184")
		light.light_energy = 1.6
		light.omni_range = 9
		light.shadow_enabled = true
		scene.add_child(light)
		light.owner = scene
	var fill := OmniLight3D.new()
	fill.name = "TableFill"
	fill.position = Vector3(0,4,1)
	fill.light_color = Color("d6af78")
	fill.light_energy = 0.8
	fill.omni_range = 9
	scene.add_child(fill)
	fill.owner = scene
	var env := WorldEnvironment.new()
	env.name = "Environment"
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("030405")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	scene.add_child(env)
	env.owner = scene
	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0,6.1,7.0)
	camera.rotation_degrees.x = -43
	camera.fov = 56
	camera.current = true
	scene.add_child(camera)
	camera.owner = scene
	var packed := PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,"res://art/duel/duel_table.tscn")==OK)
	scene.free()
	quit()

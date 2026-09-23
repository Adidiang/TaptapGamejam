class_name TableStage
extends SubViewportContainer
## Placeholder 3D environment. Replace meshes/materials with art later.
var decorative_cards := true

func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1000, 440)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.own_world_3d = true
	add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("10191e")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("76918f")
	settings.ambient_light_energy = 0.42
	environment.environment = settings
	world.add_child(environment)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0, 6.4, 7.6)
	camera.look_at(Vector3(0, 0, -0.2))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = 10.8
	camera.current = true
	_box(world, Vector3(9, 0.3, 5.1), Vector3(0, -0.2, 0), Color("493c31"))
	_box(world, Vector3(8.5, 0.06, 4.65), Vector3(0, 0, 0), Color("20433f"))
	# Table trim and opposing card backs establish the scale of the scene.
	for x in [-4.08, 4.08]:
		_box(world, Vector3(0.025, 0.015, 4.2), Vector3(x, 0.05, 0), Color("aa925b"))
	for z in [-2.08, 2.08]:
		_box(world, Vector3(8.18, 0.015, 0.025), Vector3(0, 0.05, z), Color("aa925b"))
	for x in ([-0.52, 0.52] if decorative_cards else []):
		_box(world, Vector3(0.8, 0.035, 1.18), Vector3(x, 0.06, -1.15), Color("b9aa8a"))
		_box(world, Vector3(0.68, 0.02, 1.05), Vector3(x, 0.085, -1.15), Color("384c60"))
	_box(world, Vector3(0.8, 0.24, 1.18), Vector3(3.1, 0.15, 0.1), Color("b9aa8a"))
	_box(world, Vector3(0.72, 0.02, 1.1), Vector3(3.1, 0.28, 0.1), Color("384c60"))
	_box(world, Vector3(0.28, 0.72, 0.28), Vector3(-3.1, 0.4, -1.0), Color("e4d8b5"))
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(-3.1, 1.5, -1)
	lamp.light_color = Color("ffd393")
	lamp.light_energy = 3.0
	lamp.omni_range = 9
	lamp.shadow_enabled = true
	world.add_child(lamp)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-65, -30, 0)
	fill.light_color = Color("a4becb")
	fill.light_energy = 0.55
	world.add_child(fill)

func _box(parent: Node3D, dimensions: Vector3, at: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)

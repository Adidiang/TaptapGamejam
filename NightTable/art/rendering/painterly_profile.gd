extends Resource
## One shared style preset; original textures and mesh materials remain untouched.
@export var enabled := true
@export_range(0.0,6.0) var texture_softness := 3.2
@export_range(3.0,24.0) var color_steps := 9.0
@export_range(0.0,1.5) var saturation := 0.8
@export var ambient_color := Color("687f91")
@export var ambient_energy := 0.42
@export var key_color := Color("aabbd4")
@export var key_energy := 0.28
@export var candle_energy_scale := 0.8
@export_group("Storybook surface")
@export_range(0.0,1.0) var storybook_strength := 0.0
@export_range(0.0,0.08) var paper_grain := 0.018
@export_group("Dream atmosphere")
@export var mist_enabled := true
@export var mist_color := Color("718b99")
@export_range(0.0,0.15) var mist_density := 0.019
@export_range(0.0,2.0) var glow_strength := 0.55
@export_range(0.0,1.0) var screen_softness := 0.17
@export_range(0.0,0.3) var drifting_mist := 0.07
const PAINT_SHADER = preload("res://art/rendering/painterly.gdshader")
const DREAM_SHADER = preload("res://art/rendering/dream_glow.gdshader")
var _materials: Dictionary = {}
var _halo_material: StandardMaterial3D

func screen_material() -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = DREAM_SHADER
	result.set_shader_parameter("glow_strength",glow_strength if mist_enabled else 0.0)
	result.set_shader_parameter("softness",screen_softness if mist_enabled else 0.0)
	result.set_shader_parameter("mist_strength",drifting_mist if mist_enabled else 0.0)
	result.set_shader_parameter("storybook_strength",storybook_strength)
	result.set_shader_parameter("paper_grain",paper_grain)
	return result

func configure_environment(environment: Environment) -> void:
	if not enabled: return
	environment.ambient_light_color = ambient_color
	environment.ambient_light_energy = ambient_energy
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = mist_enabled
	environment.fog_light_color = mist_color
	environment.fog_light_energy = 0.5
	environment.fog_density = mist_density
	environment.fog_sky_affect = 0.0

func apply_to(node: Node) -> void:
	if not enabled: return
	if node.name=="CandleHalo": return
	if node is MeshInstance3D and node.mesh!=null:
		for i in range(node.mesh.get_surface_count()):
			var original: Material = node.get_active_material(i)
			if original is StandardMaterial3D:
				node.set_surface_override_material(i,paint_material(original))
	elif node is OmniLight3D and not node.has_meta("paint_light"):
		node.set_meta("paint_light",true)
		node.light_energy *= candle_energy_scale
		if node.light_color.r > node.light_color.b:
			node.light_color = Color("ffc184")
			if mist_enabled and node.name!="CeilingFill": add_halo(node)
	elif node is DirectionalLight3D:
		node.light_color = key_color
		node.light_energy = key_energy
	elif node is WorldEnvironment:
		# Scene subresources are shared; duplicate before preview customization.
		node.environment = node.environment.duplicate()
		configure_environment(node.environment)
	for child in node.get_children(): apply_to(child)

func add_halo(lamp: OmniLight3D) -> void:
	if _halo_material==null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0,0.15,0.45,1.0])
		gradient.colors = PackedColorArray([Color(1,0.64,0.28,0.28),Color(1,0.62,0.25,0.14),Color(1,0.55,0.22,0.045),Color(1,0.5,0.2,0)])
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.width = 128
		texture.height = 128
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5,0.5)
		texture.fill_to = Vector2(1,0.5)
		_halo_material = StandardMaterial3D.new()
		_halo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_halo_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_halo_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_halo_material.no_depth_test = false
		_halo_material.albedo_texture = texture
	var halo := MeshInstance3D.new()
	halo.name = "CandleHalo"
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE*2.2
	halo.mesh = quad
	halo.material_override = _halo_material
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lamp.add_child(halo)

func paint_material(original: StandardMaterial3D) -> ShaderMaterial:
	var key := original.get_instance_id()
	if _materials.has(key): return _materials[key]
	var paint := ShaderMaterial.new()
	paint.shader = PAINT_SHADER
	if original.albedo_texture!=null: paint.set_shader_parameter("color_map",original.albedo_texture)
	paint.set_shader_parameter("base_color",original.albedo_color)
	paint.set_shader_parameter("texture_softness",texture_softness)
	paint.set_shader_parameter("color_steps",color_steps)
	paint.set_shader_parameter("saturation",saturation)
	paint.set_shader_parameter("storybook_strength",storybook_strength)
	paint.set_shader_parameter("cutout",original.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED)
	paint.set_shader_parameter("cutoff",original.alpha_scissor_threshold)
	_materials[key] = paint
	return paint

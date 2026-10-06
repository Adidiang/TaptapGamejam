extends Node3D
## Exploration visual only: movement/collisions remain owned by CastleExploration.
@export var model_scale := 0.58
@export var turn_speed := 12.0
@export var animation_blend := 0.18
@export_range(0.0, 1.5) var hair_gravity := 1.0
@export_range(0.0, 2.0) var hair_running_sway := 1.0
@export var hair_spring_stiffness := 24.0
@export var hair_spring_damping := 7.0
var animation_player: AnimationPlayer
var hair: MeshInstance3D
var _hair_shapes: Dictionary = {}
var _hair_lift := 0.0
var _hair_velocity := 0.0
var _hair_time := 0.0
var _moving := false
var _target_yaw := 0.0

func _ready() -> void:
	$Model.scale = Vector3.ONE * model_scale
	for node in find_children("*", "MeshInstance3D", true, false):
		node.layers = 65535
		node.extra_cull_margin = 0.4
		if node.name == "Hair": hair = node
	if hair:
		for index in hair.mesh.get_blend_shape_count():
			_hair_shapes[str(hair.mesh.get_blend_shape_name(index))] = index
	for node in find_children("*", "AnimationPlayer", true, false):
		animation_player = node
		break
	if animation_player:
		# Body clips crossfade normally; hair must retain inertia across clip changes.
		# Duplicate before removing morph tracks so the imported resource stays intact.
		var library := AnimationLibrary.new()
		for clip in ["Idle", "Run01"]:
			if animation_player.has_animation(clip):
				var animation: Animation = animation_player.get_animation(clip).duplicate()
				for index in range(animation.get_track_count()-1, -1, -1):
					if animation.track_get_type(index) == Animation.TYPE_BLEND_SHAPE:
						animation.remove_track(index)
				animation.loop_mode = Animation.LOOP_LINEAR
				library.add_animation(clip, animation)
		for name in animation_player.get_animation_library_list():
			animation_player.remove_animation_library(name)
		animation_player.add_animation_library("", library)
		animation_player.play("Idle")
	_apply_hair()

func _process(delta: float) -> void:
	# Small integration steps keep the damped spring stable after a slow frame.
	var remaining := minf(delta, 0.1)
	while remaining > 0.00001:
		var step := minf(remaining, 1.0/120.0)
		var target := 1.0 if _moving else 0.0
		_hair_velocity += ((target-_hair_lift)*hair_spring_stiffness-_hair_velocity*hair_spring_damping)*step
		_hair_lift += _hair_velocity*step
		_hair_time += step
		remaining -= step
	_apply_hair()

func _set_hair_shape(name: String, value: float) -> void:
	if hair and _hair_shapes.has(name):
		hair.set_blend_shape_value(_hair_shapes[name], value)

func _apply_hair() -> void:
	var lift := clampf(_hair_lift, -0.12, 1.15)
	_set_hair_shape("Gravity_Rest", hair_gravity*(1.0-0.35*lift))
	_set_hair_shape("Wind_Back", 0.75*lift)
	# Only a small residual motion when settled; running adds stronger ripples.
	var amplitude := 0.025 + maxf(lift, 0.0)*hair_running_sway
	var phase := _hair_time*TAU/1.95
	var names := ["Long_Wave", "Cross_Wave", "Tip_Ripple"]
	var frequencies := [3.0, 2.0, 5.0]
	for index in names.size():
		_set_hair_shape(names[index]+"_Sin", amplitude*cos(phase*frequencies[index]))
		_set_hair_shape(names[index]+"_Cos", amplitude*sin(phase*frequencies[index]))

func update_locomotion(direction: Vector2, delta: float) -> void:
	var moving := direction.length_squared() > 0.000001
	if moving:
		_target_yaw = atan2(direction.x, direction.y)
	rotation.y = lerp_angle(rotation.y, _target_yaw, 1.0-exp(-turn_speed*delta))
	if moving != _moving:
		_moving = moving
		if animation_player:
			animation_player.play("Run01" if moving else "Idle", animation_blend)

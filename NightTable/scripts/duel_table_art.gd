extends Node3D

func _ready() -> void:
	var profile = load("res://art/duel/duel_profile.tres").duplicate()
	profile.ambient_color = Color("505c6b")
	profile.ambient_energy = 0.22
	profile.key_energy = 0.18
	profile.texture_softness = 1.4
	profile.color_steps = 14.0
	profile.mist_enabled = false
	profile.candle_energy_scale = 1.0
	profile.apply_to(self)

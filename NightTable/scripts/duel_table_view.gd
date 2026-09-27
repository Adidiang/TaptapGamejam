extends SubViewportContainer
const TABLE = preload("res://art/duel/duel_table.tscn")

func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	viewport.add_child(TABLE.instantiate())
	var profile = load("res://art/duel/duel_profile.tres").duplicate()
	profile.glow_strength = 0.35
	profile.drifting_mist = 0.015
	material = profile.screen_material()

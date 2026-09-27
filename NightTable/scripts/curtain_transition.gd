class_name CurtainTransition
extends CanvasLayer
## A reusable screen curtain. Swap scenes only while both opaque panels meet.
var busy := false
var progress := 0.0
var duration := 0.42
var cover: ColorRect
var fabric: ShaderMaterial

func _ready() -> void:
	layer = 100
	cover = ColorRect.new()
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	cover.color = Color.WHITE
	add_child(cover)
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float closure : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec2 p = UV;
	float half_x = min(p.x, 1.0-p.x);
	float edge = closure*0.5;
	float inside = step(half_x, edge);
	if (closure < 0.0001) inside = 0.0;
	if (closure > 0.9999) inside = 1.0;
	float cloth_x = half_x + (1.0-closure)*0.5;
	float fold = 0.5 + 0.5*cos(cloth_x*170.0 + 0.4*sin(p.y*4.0));
	float fine_fold = 0.5 + 0.5*cos(cloth_x*340.0);
	vec3 velvet = mix(vec3(0.085,0.018,0.035), vec3(0.34,0.075,0.10), pow(fold,1.4));
	velvet *= 0.78 + 0.22*fine_fold;
	velvet *= 0.70 + 0.30*sin(p.y*3.14159);
	float seam = 1.0-smoothstep(0.0015,0.0035,abs(half_x-edge+0.007));
	float hem = 1.0-smoothstep(0.001,0.003,abs(p.y-0.945));
	vec3 gold = vec3(0.60,0.40,0.18)*(0.65+0.35*fold);
	velvet = mix(velvet,gold,max(seam,hem*0.6));
	COLOR = vec4(velvet,inside);
}
"""
	fabric = ShaderMaterial.new()
	fabric.shader = shader
	cover.material = fabric
	cover.hide()

func set_progress(value: float) -> void:
	progress = clampf(value,0.0,1.0)
	fabric.set_shader_parameter("closure",progress)

func play(change: Callable) -> void:
	if busy: return
	busy = true
	cover.show()
	set_progress(0)
	var closing := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	closing.tween_method(set_progress,0.0,1.0,duration)
	await closing.finished
	change.call()
	# Allow full-screen containers and their 3D viewport to settle behind the curtain.
	await get_tree().process_frame
	await get_tree().process_frame
	var opening := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	opening.tween_method(set_progress,1.0,0.0,duration)
	await opening.finished
	cover.hide()
	busy = false

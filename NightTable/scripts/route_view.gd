class_name RouteView
extends Control

signal node_selected(node_id: int)

var run: NightRun
var points: Dictionary = {}
var node_buttons: Dictionary = {}
const GOLD := Color("d5ba7d")

func configure(state: NightRun) -> void:
	run = state
	custom_minimum_size = Vector2(600, 420)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for layer in run.layers:
		for node in layer:
			var button := Button.new()
			button.text = "%s  %s" % [RouteGenerator.symbol(node.kind), RouteGenerator.title(node.kind)]
			button.disabled = node.id not in run.available_ids()
			button.tooltip_text = "已走过" if node.id in run.visited else ("选择此节点" if not button.disabled else "沿路线解锁")
			if node.id in run.visited:
				button.text = "✓  " + RouteGenerator.title(node.kind)
			button.pressed.connect(func(): node_selected.emit(node.id))
			add_child(button)
			node_buttons[node.id] = button
	resized.connect(_arrange)
	call_deferred("_arrange")

func _arrange() -> void:
	if run == null:
		return
	points.clear()
	for layer in run.layers:
		for node in layer:
			var x := 84.0 + float(node.row) / (run.layers.size() - 1) * (size.x - 168.0)
			var y: float = size.y * (float(node.column + 1) / (layer.size() + 1))
			points[node.id] = Vector2(x, y)
			var button: Button = node_buttons[node.id]
			button.position = Vector2(x - 59, y - 25)
			button.size = Vector2(118, 50)
	queue_redraw()

func _draw() -> void:
	if run == null:
		return
	for layer in run.layers:
		for node in layer:
			if not points.has(node.id):
				continue
			for next_id in node.next:
				if not points.has(next_id):
					continue
				var traveled: bool = node.id in run.visited and next_id in run.visited
				var color := GOLD if traveled else Color("344348")
				draw_line(points[node.id], points[next_id], color, 2.5 if traveled else 1.5, true)
			if node.id in run.available_ids():
				draw_circle(points[node.id], 41, Color(0.83, 0.73, 0.49, 0.12))

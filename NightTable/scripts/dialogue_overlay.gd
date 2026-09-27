class_name DialogueOverlay
extends CanvasLayer
## UI and input only: encounter state and scene transitions remain in the host.
signal finished
var active := false
var lines: Array = []
var index := 0
var opened_frame := -1
var finish_label := "进入对战"
var root: Control
var portrait_placeholder: ColorRect
var portrait: TextureRect
var speaker: Label
var speech: Label
var prompt: Label

func _ready() -> void:
	layer = 50
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.theme = get_parent().theme
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.015,0.02,0.03,0.35)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	portrait_placeholder = ColorRect.new()
	portrait_placeholder.color = Color.BLACK
	root.add_child(portrait_placeholder)
	_place(portrait_placeholder,0.72,0.10,0.94,0.87)
	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root.add_child(portrait)
	_place(portrait,0.62,0.08,0.97,0.90)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("141b24")
	style.border_color = Color("b39869")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 24
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel",style)
	root.add_child(panel)
	_place(panel,0.045,0.58,0.955,0.95)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",16)
	panel.add_child(column)
	speaker = Label.new()
	speaker.add_theme_font_size_override("font_size",26)
	speaker.add_theme_color_override("font_color",Color("dfc18a"))
	column.add_child(speaker)
	speech = Label.new()
	speech.add_theme_font_size_override("font_size",28)
	speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speech.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(speech)
	prompt = Label.new()
	prompt.add_theme_font_size_override("font_size",17)
	prompt.add_theme_color_override("font_color",Color("a99b85"))
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(prompt)
	root.hide()

func _place(node: Control, left: float, top: float, right: float, bottom: float) -> void:
	node.anchor_left = left
	node.anchor_top = top
	node.anchor_right = right
	node.anchor_bottom = bottom
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE

func begin(script_lines: Array, last_action: String = "进入对战") -> void:
	if active or script_lines.is_empty(): return
	lines = script_lines.duplicate(true)
	index = 0
	finish_label = last_action
	active = true
	opened_frame = Engine.get_process_frames()
	root.show()
	_refresh()

func _refresh() -> void:
	var line: Dictionary = lines[index]
	speaker.text = line.get("speaker","")
	speech.text = line.get("text","")
	portrait.texture = line.get("portrait",null)
	portrait.visible = portrait.texture!=null
	portrait_placeholder.visible = portrait.texture==null
	prompt.text = "%d / %d    ·    F / 空格 / 点击%s" % [index+1,lines.size(),finish_label+"  ▸" if index==lines.size()-1 else "继续  ▸"]

func advance() -> void:
	if not active: return
	if index+1<lines.size():
		index += 1
		_refresh()
	else:
		active = false
		root.hide()
		finished.emit()

func _input(event: InputEvent) -> void:
	if not active: return
	get_viewport().set_input_as_handled()
	# The F press that opened the overlay must not also skip its first line.
	if Engine.get_process_frames()<=opened_frame: return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_F,KEY_SPACE]:
		advance()
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		advance()

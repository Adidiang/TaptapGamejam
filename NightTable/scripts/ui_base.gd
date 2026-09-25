extends Control
const INK := Color("10191e")
const PANEL := Color("17252b")
const GOLD := Color("d5ba7d")
const TEXT := Color("e4e3d9")
const MUTED := Color("92a8aa")
var page: VBoxContainer
var screen := "menu"
var ui_root: MarginContainer
func _build_theme() -> void:
	var ui_theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "sans-serif"])
	ui_theme.default_font = font
	ui_theme.default_font_size = 18
	ui_theme.set_color("font_color", "Label", TEXT)
	ui_theme.set_color("font_color", "Button", TEXT)
	ui_theme.set_color("font_hover_color", "Button", Color("fff2ce"))
	ui_theme.set_color("font_disabled_color", "Button", Color("657b80"))
	ui_theme.set_stylebox("normal", "Button", _style(Color("213239"), Color("465550"), 8))
	ui_theme.set_stylebox("hover", "Button", _style(Color("35433e"), GOLD, 8))
	ui_theme.set_stylebox("pressed", "Button", _style(Color("465047"), GOLD, 8))
	ui_theme.set_stylebox("disabled", "Button", _style(Color("152228"), Color("2a3a40"), 8))
	ui_theme.set_stylebox("focus", "Button", _style(Color(0, 0, 0, 0), GOLD, 8))
	theme = ui_theme
	var backdrop := ColorRect.new()
	backdrop.color = INK
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	ui_root = MarginContainer.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		ui_root.add_theme_constant_override("margin_" + side, 64)
	for side in ["top", "bottom"]:
		ui_root.add_theme_constant_override("margin_" + side, 32)
	add_child(ui_root)

func _style(fill: Color, border: Color, radius: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _new_page(name_of_screen: String, heading: String, subtitle: String) -> void:
	screen = name_of_screen
	if is_instance_valid(page):
		ui_root.remove_child(page)
		page.queue_free()
	page = VBoxContainer.new()
	page.add_theme_constant_override("separation", 18)
	ui_root.add_child(page)
	var top := HBoxContainer.new()
	page.add_child(top)
	_label(top, "N / T     余夜", 20, GOLD).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(top, "可玩原型   /   0.4", 15, MUTED)
	var line := HSeparator.new()
	page.add_child(line)
	_label(page, heading, 36)
	_label(page, subtitle, 17, MUTED)

func _label(parent: Node, text: String, font_size: int = 20, color: Color = TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, action: Callable, width: float = 150) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width, 48)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _spacer(parent: Node) -> Control:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)
	return spacer

func _panel(parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(PANEL, Color("34454a")))
	parent.add_child(panel)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 14)
	panel.add_child(contents)
	return contents



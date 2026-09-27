extends Button
## Ink-and-paper card face. Hidden cards are configured without a card definition.
var title := ""
var subtitle := ""
var value := ""
var load_text := ""
var sigil := "number"
var face_down := false
var vacant := false
var small := false
var ink := Color("35271d")
var font: SystemFont

func _ready() -> void:
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei","Noto Sans CJK SC"])
	for style in ["normal","hover","pressed","disabled","focus"]:
		add_theme_stylebox_override(style,StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	resized.connect(queue_redraw)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not disabled else Control.CURSOR_ARROW

func write(line: String, y: float, point_size: int, color: Color) -> void:
	var width = font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,point_size).x
	draw_string(font,Vector2((size.x-width)*0.5,y),line,HORIZONTAL_ALIGNMENT_LEFT,-1,point_size,color)

func _draw() -> void:
	if font==null: return
	var rect := Rect2(Vector2(3,3),size-Vector2(8,10))
	if vacant:
		draw_rect(rect,Color(0.09,0.065,0.04,0.3))
		draw_rect(rect.grow(-5),Color(0.7,0.52,0.29,0.35),false,1)
		write("◇",size.y*0.5,26,Color("96774b"))
		write("空槽",size.y*0.7,13,Color("96774b"))
		return
	draw_rect(Rect2(rect.position+Vector2(5,6),rect.size),Color(0,0,0,0.55))
	var paper := Color("4a3027") if face_down else Color("cbb381")
	if is_hovered() and not disabled: paper = paper.lightened(0.13)
	draw_style_box(paper_style(paper),rect)
	for i in range(30):
		var x = 8+fmod(i*37.73,size.x-16)
		var y = 8+fmod(i*23.57,size.y-20)
		draw_line(Vector2(x,y),Vector2(minf(x+7,size.x-9),y+1),Color(0.2,0.12,0.04,0.06),1)
	var edge := Color("b08a4d") if face_down else ink
	draw_rect(rect.grow(-7),edge,false,1.4)
	draw_rect(rect.grow(-10),Color(edge,0.35),false,1)
	if face_down:
		var center := size*Vector2(0.5,0.48)
		for radius in [20.0,26.0,31.0]: draw_arc(center,radius,0,TAU,40,edge,1.2,true)
		draw_line(center+Vector2(-24,0),center+Vector2(0,-12),edge,2,true)
		draw_line(center+Vector2(0,-12),center+Vector2(24,0),edge,2,true)
		draw_line(center+Vector2(24,0),center+Vector2(0,12),edge,2,true)
		draw_line(center+Vector2(0,12),center+Vector2(-24,0),edge,2,true)
		draw_circle(center,5,edge)
		write("余 夜",size.y-25,15,edge)
		return
	write(title,27,15,ink)
	draw_line(Vector2(13,34),Vector2(size.x-17,34),ink,1)
	var center := Vector2(size.x*0.5,size.y*0.49)
	if sigil=="number":
		write(value,size.y*0.65,48 if not small else 38,ink)
		for i in range(3):
			var x := size.x*0.5+(i-1)*13
			draw_circle(Vector2(x,size.y*0.74),2.2,ink)
	else:
		var r := 23.0
		draw_arc(center,r,0,TAU,32,ink,1.6,true)
		if sigil=="effect":
			for i in range(8):
				var dir := Vector2.from_angle(i*TAU/8)
				draw_line(center+dir*13,center+dir*29,ink,2,true)
			draw_circle(center,7,ink)
		elif sigil=="bonus":
			draw_polyline(PackedVector2Array([center+Vector2(-21,-9),center+Vector2(-14,13),center+Vector2(14,13),center+Vector2(21,-9),center+Vector2(8,1),center+Vector2(0,-17),center+Vector2(-8,1),center+Vector2(-21,-9)]),ink,2,true)
		else:
			for i in range(6):
				var dir := Vector2.from_angle(i*TAU/6)
				draw_line(center-dir*22,center+dir*22,ink,1,true)
			draw_arc(center,12,0,TAU,6,ink,2,true)
		write(subtitle,size.y*0.77,13,ink)
	draw_line(Vector2(13,size.y-35),Vector2(size.x-17,size.y-35),ink,1)
	write(load_text,size.y-18,13,ink)
	if has_focus(): draw_rect(rect.grow(2),Color("ffe2a0"),false,2)

func paper_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("6d4b2b")
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	return style

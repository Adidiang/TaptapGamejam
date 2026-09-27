class_name CastleView
extends SubViewportContainer
## Replace meshes here without changing generation, movement, or encounter state.
signal battle_requested
signal content_requested
signal hint_changed(text: String)
const W := CastleGenerator.ROOM_WIDTH
const H := CastleGenerator.FLOOR_HEIGHT
const ROOM_ART = preload("res://art/room_studies/room_catalog.tres")
const ROOM_CAMERA_PITCH := 15.0
const PLAYER_VISUAL_SCALE := 0.52
const PAINT_STYLE = preload("res://art/rendering/painterly_profile.tres")
var state: CastleExploration
var world: Node3D
var camera: Camera3D
var actor: Node3D
var interaction_label: Label3D
var room_visuals: Dictionary = {}
var gates: Array = []
var ladder_visuals: Array = []
var focused := true
var minimap_mode := false
var minimap: CastleView
var door_leaves: Array = []

func configure(exploration: CastleExploration, as_minimap: bool = false) -> void:
	state = exploration
	minimap_mode = as_minimap
	stretch = true
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2.ZERO if minimap_mode else Vector2(800,400)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
	if not minimap_mode and PAINT_STYLE.enabled: material = PAINT_STYLE.screen_material()
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1200,600)
	viewport.own_world_3d = true
	if not minimap_mode: viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	world = Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("050608")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("98abc0")
	settings.ambient_light_energy = 0.7
	if not minimap_mode:
		settings.ambient_light_color = Color("acb5cf")
		settings.ambient_light_energy = 0.36
		settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		PAINT_STYLE.configure_environment(settings)
	environment.environment = settings
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35,-25,0)
	light.light_color = Color("d6c9b4")
	light.light_energy = 1.25
	if not minimap_mode:
		light.rotation_degrees = Vector3(-55,-25,0)
		light.light_color = Color("c3d4ea")
		light.light_energy = 0.45
		light.shadow_enabled = true
	world.add_child(light)
	if not minimap_mode: PAINT_STYLE.apply_to(light)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = 17.0
	camera.position = Vector3(state.player_x,state.room().floor*H+2.5,45)
	camera.current = true
	world.add_child(camera)
	if not minimap_mode:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = 36
		camera.rotation_degrees.x = -ROOM_CAMERA_PITCH
	_build_castle()
	actor = Node3D.new()
	world.add_child(actor)
	var body := Node3D.new()
	body.name = "Visual"
	actor.add_child(body)
	if not minimap_mode: body.scale = Vector3.ONE*PLAYER_VISUAL_SCALE
	_box(body,Vector3(0.8,1.35,0.7),Vector3(0,0.8,0),Color("e9c67d"))
	_box(body,Vector3(0.62,0.6,0.65),Vector3(0,1.78,0),Color("f4dfad"))
	_box(body,Vector3(0.42,0.15,0.1),Vector3(0,1.82,0.4),Color("26333f"))
	if not minimap_mode: PAINT_STYLE.apply_to(body)
	_text(actor,"你",Vector3(0,2.4 if minimap_mode else 1.35,0),Color("ffdf91"),26)
	interaction_label = _text(actor,"",Vector3(0,3.2 if minimap_mode else 1.8,0.3),Color("ffe4aa"),23)
	_sync()
	resized.connect(_snap_camera)
	call_deferred("_snap_camera")
	if not minimap_mode: _build_minimap()

func _build_minimap() -> void:
	var frame := PanelContainer.new()
	frame.name = "MinimapFrame"
	var style := StyleBoxFlat.new()
	style.bg_color = Color("080c12")
	style.border_color = Color("b6a071")
	style.set_border_width_all(2)
	style.set_content_margin_all(4)
	frame.add_theme_stylebox_override("panel",style)
	add_child(frame)
	frame.anchor_left = 0.73
	frame.anchor_right = 0.985
	frame.anchor_top = 0.025
	frame.anchor_bottom = 0.30
	minimap = CastleView.new()
	minimap.name = "Minimap"
	minimap.configure(state,true)
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(minimap)
	frame.tooltip_text = "平视小地图 · 金色角色为当前位置 · Tab 切换局部 / 全图"
	frame.mouse_filter = Control.MOUSE_FILTER_PASS

func _snap_camera() -> void:
	if is_instance_valid(camera): _update_camera(1.0)

func _box(parent: Node3D, dimensions: Vector3, location: Vector3, color: Color, glow: bool = false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	if glow:
		material.emission_enabled = true
		material.emission = color
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = location
	parent.add_child(instance)
	return instance

func _text(parent: Node3D, value: String, location: Vector3, color: Color, font_size_value: int = 32) -> Label3D:
	var label := Label3D.new()
	label.text = value
	label.position = location
	label.font_size = font_size_value
	label.pixel_size = 0.022 if minimap_mode else 0.0055
	label.modulate = color
	label.outline_size = 5
	if not minimap_mode: label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei","Noto Sans CJK SC"])
	label.font = font
	parent.add_child(label)
	return label

func _build_castle() -> void:
	var tones := [Color("35424e"),Color("414a59"),Color("4c4655")]
	# A sliced dollhouse: back walls and depth, no front facade obscuring the player.
	for room in state.layout.rooms:
		var node := Node3D.new()
		node.position = Vector3(room.column*W,room.floor*H,0)
		world.add_child(node)
		var art: Node3D = null
		if not minimap_mode:
			art = ROOM_ART.scene_for(room.kind).instantiate()
			art.name = "RoomArt"
			art.prepare_for_gameplay()
			node.add_child(art)
		var tint: Color = Color("554535") if room.kind=="boss" else tones[room.style]
		if minimap_mode:
			_box(node,Vector3(W-0.2,H-0.3,0.45),Vector3(0,H/2,-1.6),tint)
			_box(node,Vector3(W,0.35,4),Vector3(0,-0.12,0),Color("747379"))
			_box(node,Vector3(W,0.25,2),Vector3(0,H-0.3,-0.5),Color("73707a"))
			for x in [-W/2,W/2]:
				_box(node,Vector3(0.4,H-2.7,1),Vector3(x,(H+2.7)/2,-0.3),Color("72727d"))
				_box(node,Vector3(1.4,0.25,1),Vector3(x,2.75,-0.3),Color("8b8280"))
		# Inset windows and simple sconces give scale without external assets.
		for x in [-3.2,3.2] if minimap_mode else []:
			_box(node,Vector3(1.15,2.0,0.12),Vector3(x,3.7,-1.28),Color("172839"))
			_box(node,Vector3(0.08,2.0,0.15),Vector3(x,3.7,-1.15),Color("b9a073"))
			_box(node,Vector3(1.15,0.08,0.15),Vector3(x,3.7,-1.15),Color("b9a073"))
			_box(node,Vector3(0.22,0.5,0.2),Vector3(x,2.15,-0.8),Color("e9a25a"),true)
		if room.floor==0 and minimap_mode:
			_box(node,Vector3(1.3,0.8,0.8),Vector3(3.8,0.5,0),Color("67513e"))
		var label := _text(node,"",Vector3(0,5.2 if minimap_mode else 3.5,1.1 if minimap_mode else -1.0),Color("ddd1ae"),29)
		var marker := Node3D.new()
		node.add_child(marker)
		if minimap_mode:
			_box(marker,Vector3(1.2,0.75,0.8),Vector3(0,0.48,0.8),Color("5b353a"))
			_box(marker,Vector3(0.75,0.22,0.6),Vector3(0,0.98,0.8),Color("e3a762"),true)
		var marker_text := _text(marker,_room_type(room.kind),Vector3(0,3.35,1.4),Color("ffbc86"),31)
		if room.kind=="boss" and minimap_mode:
			_box(node,Vector3(2.5,3.7,0.4),Vector3(0,2.2,-1.15),Color("74393f"))
		# Separate frontier shell: no interior, gates, furniture or room numbers leak.
		var fog := Node3D.new()
		fog.position = node.position
		world.add_child(fog)
		var fill := _box(fog,Vector3(W-0.12,H-0.12,0.1),Vector3(0,H/2,3),Color("08090b"))
		fill.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		for y in [0.0,H]:
			var edge := _box(fog,Vector3(W,0.07,0.1),Vector3(0,y,3.1),Color("35383e"))
			edge.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		for x in [-W/2,W/2]:
			var edge := _box(fog,Vector3(0.07,H,0.1),Vector3(x,H/2,3.1),Color("35383e"))
			edge.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_text(fog,_room_type(room.kind),Vector3(0,H/2,3.2),Color("b9a58a"),34)
		room_visuals[room.id] = {"node":node,"art":art,"fog":fog,"marker":marker,"marker_text":marker_text,"label":label}
		# Every boundary has a visible gate: exterior walls stay shut.
		for direction in [-1,1]:
			var destination := -1
			for id in room.neighbors:
				if state.layout.rooms[id].column==room.column+direction: destination = id
			if not minimap_mode:
				_build_art_door(art,room.id,destination,direction)
				continue
			var gate := Node3D.new()
			gate.position = Vector3(direction*W/2,0,1.4)
			node.add_child(gate)
			for x in [-0.24,0.0,0.24]: _box(gate,Vector3(0.12,2.55,0.2),Vector3(x,1.3,0),Color("a67462"))
			gates.append({"node":gate,"room":room.id,"neighbor":destination})
	for ladder in state.layout.ladders:
		var lower: Dictionary = state.layout.rooms[ladder.lower]
		var node := Node3D.new()
		node.position = Vector3(ladder.x,lower.floor*H,1.0)
		room_visuals[ladder.lower].node.add_child(node)
		node.position = Vector3(ladder.x-lower.column*W,0,1.0 if minimap_mode else 2.8)
		if minimap_mode:
			for x in [-0.42,0.42]: _box(node,Vector3(0.11,H+0.3,0.15),Vector3(x,H/2,0),Color("d6ad65"))
			for rung in range(12): _box(node,Vector3(0.9,0.1,0.15),Vector3(0,rung*H/11,0),Color("d6ad65"))
		else:
			node.add_child(ROOM_ART.ladder.instantiate())
			PAINT_STYLE.apply_to(node)
		_text(node,"↑ F",Vector3(0,1.25,0.4),Color("efcd84"),24)
		var upper: Dictionary = state.layout.rooms[ladder.upper]
		var down := _text(room_visuals[ladder.upper].node,"↓ F",Vector3(ladder.x-upper.column*W,1.25,1.4),Color("efcd84"),24)
		ladder_visuals.append({"node":node,"down":down,"id":ladder.id})
	# Roof crenellations and dark foundation reinforce the castle silhouette.
	for room in state.layout.rooms if minimap_mode else []:
		var has_above := false
		for other in state.layout.rooms:
			if other.column==room.column and other.floor==room.floor+1: has_above = true
		if not has_above:
			for x in [-4.5,-2.7,-0.9,0.9,2.7,4.5]:
				_box(room_visuals[room.id].node,Vector3(0.9,0.8,1.5),Vector3(x,H,0),Color("6f737f"))

func _build_art_door(art: Node3D, room_id: int, neighbor: int, direction: int) -> void:
	var doorway: Node3D = ROOM_ART.doorway.instantiate()
	doorway.name = "LeftDoor" if direction<0 else "RightDoor"
	doorway.position = art.door_position(direction)
	art.add_child(doorway)
	PAINT_STYLE.apply_to(doorway)
	doorway.get_node("SealedWall").visible = neighbor<0
	doorway.get_node("Opening").visible = neighbor>=0
	if neighbor<0: return
	var hinge: Node3D = doorway.get_node("Opening/Hinge")
	var sign := _text(doorway,"",Vector3(-direction*0.6,3.65,0),Color("e6c58a"),22)
	door_leaves.append({"hinge":hinge,"room":room_id,"neighbor":neighbor,"direction":direction,"sign":sign,"initialized":false,"closed":true})

func door_closed(room_id: int, neighbor: int) -> bool:
	return neighbor<0 or not state.can_pass(room_id,neighbor) or (state.locked() and state.current in [room_id,neighbor])

func _room_type(kind: String) -> String:
	match kind:
		"boss": return "BOSS 战斗"
		"event": return "事件"
		"shop": return "商店"
		"spawn": return "出生点"
		_: return "战斗"

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT: focused = false
	elif what==NOTIFICATION_WM_WINDOW_FOCUS_IN: focused = true

func _input(event: InputEvent) -> void:
	if minimap_mode or state==null or not is_visible_in_tree() or not focused: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_TAB:
			state.overview = not state.overview
			get_viewport().set_input_as_handled()
		elif event.physical_keycode==KEY_F:
			get_viewport().set_input_as_handled()
			perform_interaction()

func perform_interaction() -> void:
	var result := state.interact()
	_sync()
	if result=="battle": battle_requested.emit()
	elif result=="content": content_requested.emit()

func _process(delta: float) -> void:
	if state==null or not is_visible_in_tree() or not is_instance_valid(actor): return
	if focused and not minimap_mode:
		var direction := float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
		state.move(direction*6.5*minf(delta,0.1))
	_sync()
	_update_camera(1-exp(-delta*7))

func _update_camera(weight: float) -> void:
	if not minimap_mode:
		var focus := Vector3(state.room().column*W,state.room().floor*H+1.0,0.9)
		# A small edge follow keeps the reduced character visible at both door thresholds.
		var local_x: float = state.player_x-state.room().column*W
		focus.x += signf(local_x)*clampf(absf(local_x)-2.5,0.0,1.3)
		# Fill the viewport rather than framing the outside of the room as a diorama.
		var aspect := maxf(0.5,size.x/maxf(size.y,1))
		var distance := minf(9.2,14.72/aspect)
		var target_position := focus+Vector3(0,sin(deg_to_rad(ROOM_CAMERA_PITCH))*distance,cos(deg_to_rad(ROOM_CAMERA_PITCH))*distance)
		camera.position = camera.position.lerp(target_position,weight)
		return
	var target := Vector3(state.player_x,state.room().floor*H+2.7,45)
	var zoom := 17.0
	var aspect := maxf(1.0,size.x/maxf(1.0,size.y))
	var left := -2.0 if state.layout.has("copper") else 0.0
	if state.overview:
		zoom = maxf(30.0,((state.layout.width-left)*W+4)/aspect)
		target = Vector3((state.layout.width-1+left)*W/2,13.0,45)
	else:
		var half_width := zoom*aspect/2
		var min_x := (left-0.5)*W+half_width
		var max_x: float = (state.layout.width-0.5)*W-half_width
		target.x = clampf(target.x,min_x,max_x) if min_x<max_x else (state.layout.width-1)*W/2
	camera.position = camera.position.lerp(target,weight)
	camera.size = lerpf(camera.size,zoom,weight)

func _sync() -> void:
	if not is_instance_valid(actor): return
	actor.position = Vector3(state.player_x,state.room().floor*H,2.3)
	for entry in state.layout.rooms:
		var visual: Dictionary = room_visuals[entry.id]
		var visibility := state.room_visibility(entry.id)
		# Exploration state controls visibility; camera arrival must not erase visited rooms.
		visual.node.visible = visibility==2
		# Stage one room in the main camera; the minimap retains exploration history.
		if visual.art!=null: visual.art.visible = entry.id==state.current
		visual.fog.visible = minimap_mode and visibility==1
		visual.label.visible = entry.id==state.current
		var clock: bool = entry.id==state.layout.get("clock_room",-1) and entry.get("completed",false) and not state.layout.get("clock_started",false)
		visual.marker.visible = (entry.kind in ["encounter","boss"] and not entry.triggered and not entry.cleared) or entry.kind=="shop" or (entry.kind=="event" and not entry.get("completed",false)) or clock
		if not minimap_mode: visual.marker.visible = visual.marker.visible and entry.id==state.current
		visual.marker_text.text = "F 启动钟机" if clock else _room_type(entry.kind)
		var done: bool = entry.get("completed",false) if entry.kind in ["event","shop"] else entry.cleared
		visual.label.text = "%s · %s" % [CastleGenerator.FLOOR_NAMES[entry.floor],"出生点" if entry.kind=="spawn" else ("已完成" if done else entry.get("title","房间 %02d" % (entry.id+1)))]
	for gate in gates:
		gate.node.visible = door_closed(gate.room,gate.neighbor)
	for door in door_leaves:
		var closed := door_closed(door.room,door.neighbor)
		if not door.initialized or door.closed!=closed:
			door.closed = closed
			var angle: float = 0.0 if closed else -door.direction*deg_to_rad(160.0)
			if door.initialized and is_inside_tree():
				if door.has("tween") and door.tween.is_valid(): door.tween.kill()
				door.tween = create_tween()
				door.tween.tween_property(door.hinge,"rotation:y",angle,0.24)
			else: door.hinge.rotation.y = angle
			door.initialized = true
			door.sign.text = "铜锁" if not state.can_pass(door.room,door.neighbor) else ("已锁" if closed else "通行")
	for visual in ladder_visuals:
		var enabled: bool = not state.layout.ladders[visual.id].get("hidden",false) or state.layout.get("clock_started",false)
		var ladder: Dictionary = state.layout.ladders[visual.id]
		visual.node.visible = enabled and (minimap_mode or ladder.lower==state.current)
		visual.down.visible = enabled and (minimap_mode or ladder.upper==state.current)
	var action := state.available_interaction()
	var message := "A / D 或 ← / → 移动    ·    Tab 总览 / 跟随"
	if not action.is_empty():
		match action.type:
			"battle": message = "F 开始战前对话"
			"ladder": message = "F 上楼" if action.up else "F 下楼"
			"content": message = "F "+_room_type(state.room().kind)
			"unlock": message = "F 开启铜锁" if action.ready else "需要地窖铜钥"
			"clock": message = "F 启动钟机" if action.ready else "需要停摆齿轮"
	elif state.locked(): message = "房间已锁定 · 靠近中央战斗点按 F，完成战斗后出口解锁"
	interaction_label.text = message if not minimap_mode and not action.is_empty() else ""
	hint_changed.emit("%s  |  %s" % [CastleGenerator.FLOOR_NAMES[state.room().floor],message])

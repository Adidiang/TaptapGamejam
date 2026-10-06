class_name CastleView
extends SubViewportContainer
## Editable room templates, independent from persistent route and interaction state.
signal battle_requested
signal content_requested
signal hint_changed(text: String)
const W := CastleGenerator.ROOM_WIDTH
const PAPER_FILTER = preload("res://art/exploration/room_paper_filter.tscn")
const GIRL_SCENE = preload("res://art/characters/girl/girl.tscn")
var state: CastleExploration
var world: Node3D
var camera: Camera3D
var actor: Node3D
var actor_visual: Node3D
var environment: WorldEnvironment
var interaction_label: Label3D
var room_visuals: Dictionary = {}
var door_leaves: Array = []
var focused := true
var minimap_mode := false
var minimap: CastleView
var displayed_room := -1
var outgoing_rooms: Array[int] = []
var paper_rect: ColorRect
var _loaded_state: Array = []
var _last_hint := ""
var _stream_requests: Dictionary = {}
var _stream_packed: Dictionary = {}
var streamed_instances := 0
var synchronous_room_loads := 0
var _waiting_for_room := false
var stair_links: Array=[]
var _map_expanded := false
@export var camera_follow_speed := 7.0
@export var room_transition_speed := 4.5

func configure(exploration: CastleExploration, as_minimap: bool = false) -> void:
	state = exploration
	minimap_mode = as_minimap
	stretch = true
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2.ZERO if minimap_mode else Vector2(800,400)
	mouse_filter = Control.MOUSE_FILTER_IGNORE if minimap_mode else Control.MOUSE_FILTER_STOP

func _ready() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1200,600)
	viewport.own_world_3d = true
	if not minimap_mode: viewport.msaa_3d = Viewport.MSAA_4X
	add_child(viewport)
	world = Node3D.new()
	viewport.add_child(world)
	# One screen pass per main viewport; HUD and minimap stay crisp.
	if not minimap_mode:
		var filter_node=PAPER_FILTER.instantiate()
		viewport.add_child(filter_node)
		paper_rect=filter_node.get_node("DreamFilm")
	environment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("151920")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_energy = 0.8
	world.add_child(environment)
	camera = Camera3D.new()
	camera.current = true
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	world.add_child(camera)
	if minimap_mode: camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_build_castle(state.neighbor(1))
	actor = Node3D.new()
	world.add_child(actor)
	if minimap_mode:
		# Keep a lightweight map marker instead of a second animated character.
		_box(actor,Vector3(.6,1.4,.5),Vector3(0,.8,0),Color("e9c67d"))
	else:
		actor_visual = GIRL_SCENE.instantiate()
		actor_visual.name = "Visual"
		actor.add_child(actor_visual)
	interaction_label = _text(actor,"",Vector3(0,1.65,0),Color("ffe4aa"),23)
	_sync()
	resized.connect(_snap_camera)
	call_deferred("_snap_camera")
	if not minimap_mode: _build_minimap()

func _build_minimap() -> void:
	var frame := PanelContainer.new()
	frame.name = "MinimapFrame"
	var style := StyleBoxFlat.new()
	style.bg_color = Color("151920")
	style.border_color = Color("8e9ca5")
	style.set_border_width_all(1)
	style.set_content_margin_all(3)
	frame.add_theme_stylebox_override("panel",style)
	add_child(frame)
	frame.anchor_left = 0.73
	frame.anchor_right = 0.985
	frame.anchor_top = 0.025
	frame.anchor_bottom = 0.20
	minimap = CastleView.new()
	minimap.name = "Minimap"
	minimap.configure(state,true)
	frame.add_child(minimap)
	frame.tooltip_text = "城堡探索 · 楼梯间连接楼层 · Tab 总览 / 跟随"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _box(parent: Node3D, dimensions: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	mesh.mesh.size = dimensions
	mesh.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1
	if minimap_mode: mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh

func _text(parent: Node3D, value: String, at: Vector3, color: Color, font_size_value: int = 28) -> Label3D:
	var label := Label3D.new()
	label.text = value
	label.position = at
	label.font_size = font_size_value
	label.pixel_size = 0.017 if minimap_mode else 0.0055
	label.modulate = color
	label.outline_size = 5
	if not minimap_mode: label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei","Noto Sans CJK SC"])
	label.font = font
	parent.add_child(label)
	return label

func _build_castle(detail_id: int = -1, prepared: PackedScene = null) -> void:
	for entry in state.layout.rooms:
		if room_visuals.has(entry.id):continue
		var node := Node3D.new()
		node.name = "Room_%02d" % entry.id
		node.position = Vector3(entry.column*W,entry.floor*CastleGenerator.FLOOR_HEIGHT,0)
		world.add_child(node)
		var art: Node3D = null
		var settings: Environment = null
		var film: ShaderMaterial = null
		var spec: ExplorationRoomDefinition = entry.definition
		var camera_left := spec.camera_position
		var camera_right := spec.camera_position
		if minimap_mode:
			var height: float = 4.0+CastleGenerator.FLOOR_HEIGHT*(entry.get("height_floors",1)-1)
			_box(node,Vector3(9,height,0.1),Vector3(0,height/2,0),Color("655c49") if entry.kind=="stairs" else Color("485461"))
		elif entry.id==state.current or entry.id==detail_id:
			var packed: PackedScene=prepared if entry.id==detail_id and prepared!=null else _stream_packed.get(spec.scene_path)
			if packed==null:
				synchronous_room_loads+=1
				packed=load(spec.scene_path) as PackedScene
			_stream_packed[spec.scene_path]=packed
			art = packed.instantiate()
			node.hide()
			art.name = "RoomArt"
			node.add_child(art)
			settings = art.preview_environment().duplicate()
			film = art.preview_filter()
			if film:film=film.duplicate()
			var left_anchor := art.get_node_or_null(spec.camera_left_anchor) as Camera3D if not spec.camera_left_anchor.is_empty() else null
			var right_anchor := art.get_node_or_null(spec.camera_right_anchor) as Camera3D if not spec.camera_right_anchor.is_empty() else null
			if left_anchor != null and right_anchor != null:
				camera_left = node.to_local(left_anchor.global_position)
				camera_right = node.to_local(right_anchor.global_position)
			art.prepare_for_gameplay()
			if art.has_method("configure_stairs"):art.configure_stairs(entry.stairs)
			isolate_room_lighting(art,int(entry.id))
			var bridge_width := W-spec.floor_bounds.size.x
			if bridge_width>0:
				for link in entry.get("ports",[]):
					if link.side==1:
						_box(node,Vector3(bridge_width,.1,spec.door_width),Vector3(spec.floor_bounds.end.x+bridge_width/2,spec.floor_y+link.level*CastleGenerator.FLOOR_HEIGHT-.05,spec.right_door.y),Color("887b79"))
			for level in ([0,1] if entry.kind=="stairs" else [0]):
				for direction in [-1,1]:
					var door_name := ("LeftDoor" if direction<0 else "RightDoor")
					if entry.kind=="stairs":door_name=("Lower" if level==0 else "Upper")+door_name
					var doorway := art.get_node_or_null(door_name)
					if doorway==null:continue
					var neighbor := -1
					for link in entry.get("ports",[]):
						if link.side==direction and link.level==level:neighbor=link.to
					if not entry.has("ports"):
						for id in entry.neighbors:
							if state.layout.rooms[id].floor==entry.floor and state.layout.rooms[id].column==entry.column+direction:neighbor=id
					var point := spec.door(direction)
					doorway.position=Vector3(point.x,spec.floor_y+level*CastleGenerator.FLOOR_HEIGHT,point.y)
					var sign := _text(doorway,"",Vector3(-direction*.8,2.85,0),Color("d5dfdf"),23)
					door_leaves.append({"hinge":doorway.get_node("Hinge"),"sign":sign,"room":entry.id,"neighbor":neighbor,"direction":direction,"closed":true})
		if entry.kind=="stairs":
			_text(node,"回折楼梯  %dF ↔ %dF"%[entry.floor+1,entry.floor+2],Vector3(0,5,-2.8),Color("d8c69c"),28)
		var label := _text(node,"",Vector3(0,3.5,-2.85 if not minimap_mode else 0.2),Color("e7e3d9"),28)
		label.text = "%dF-%02d · %s%s" % [entry.floor+1,entry.column+1,spec.display_name+" · " if not spec.display_name.is_empty() else "",_room_type(entry.kind)]
		var marker := Node3D.new()
		marker.position = Vector3(spec.interaction.x,spec.floor_y,spec.interaction.y)
		node.add_child(marker)
		if not minimap_mode:
			var disc := MeshInstance3D.new()
			disc.mesh = CylinderMesh.new()
			disc.mesh.top_radius = 0.38
			disc.mesh.bottom_radius = 0.38
			disc.mesh.height = 0.015
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color("ceab79")
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			disc.material_override = mat
			marker.add_child(disc)
		var marker_text := _text(marker,_room_type(entry.kind),Vector3(0,1.5,0.15),Color("e7c792"),26)
		var fog := Node3D.new()
		world.add_child(fog)
		fog.position = node.position
		if minimap_mode:
			_box(fog,Vector3(9,4,0.1),Vector3(0,2,0),Color("222832"))
			_text(fog,_room_type(entry.kind),Vector3(0,2,0.2),Color("929da5"),30)
		room_visuals[entry.id] = {"node":node,"art":art,"environment":settings,
			"camera_left":camera_left,"camera_right":camera_right,"filter":film,
			"fog":fog,"label":label,"marker":marker,"marker_text":marker_text}

func isolate_room_lighting(art: Node3D, id: int) -> void:
	# Two channels per slot preserve the auditorium's floor-only projected lighting.
	var general_bit=1<<((id%8)*2)
	var floor_bit=general_bit<<1
	var floor_projection=art.find_child("AisleWindowLight",true,false)!=null
	for mesh in art.find_children("*","GeometryInstance3D",true,false):
		mesh.layers=floor_bit if floor_projection and mesh.layers==8 else general_bit
	for light in art.find_children("*","Light3D",true,false):
		light.light_cull_mask=floor_bit if floor_projection and light.light_cull_mask==8 else general_bit

func _refresh_loaded_rooms() -> void:
	var next_state: Array = [state.current,state.layout.width,outgoing_rooms.duplicate()]
	if next_state==_loaded_state:return
	_loaded_state=next_state
	if minimap_mode:
		_build_castle()
		return
	for id in [state.current]:
		if room_visuals.has(id) and room_visuals[id].art==null:
			room_visuals[id].node.free()
			room_visuals[id].fog.free()
			room_visuals.erase(id)
	_build_castle()
	_request_nearby_rooms()

func _request_nearby_rooms() -> void:
	# Start disk parsing before the player reaches a doorway. Keep resource ownership bounded.
	var wanted: Array[String]=[]
	for id in state.nearby_rooms():
		var path: String=state.layout.rooms[id].definition.scene_path
		if path not in wanted:wanted.append(path)
		if _stream_packed.has(path) or _stream_requests.has(path):continue
		if ResourceLoader.load_threaded_request(path,"PackedScene")==OK:
			_stream_requests[path]=true

func _pump_room_stream() -> void:
	if minimap_mode:return
	for path in _stream_requests.keys():
		var status=ResourceLoader.load_threaded_get_status(path)
		if status==ResourceLoader.THREAD_LOAD_LOADED:
			_stream_packed[path]=ResourceLoader.load_threaded_get(path)
			_stream_requests.erase(path)
		elif status==ResourceLoader.THREAD_LOAD_FAILED:
			_stream_requests.erase(path)
	# Scene-tree mutations stay on the main thread, at most one room per frame,
	# and never during the actual camera transition.
	if not outgoing_rooms.is_empty():return
	# Expensive teardown is also kept out of the doorway/camera transition.
	for id in room_visuals.keys():
		var visual: Dictionary=room_visuals[id]
		if id not in state.nearby_rooms() and not outgoing_rooms.has(id) and visual.art!=null:
			visual.art.free()
			visual.art=null
			visual.environment=null
			visual.filter=null
			for i in range(door_leaves.size()-1,-1,-1):
				if door_leaves[i].room==id:door_leaves.remove_at(i)
			return
	var wanted: Array[String]=[]
	for id in state.nearby_rooms():
		wanted.append(state.layout.rooms[id].definition.scene_path)
	for path in _stream_packed.keys():
		if path not in wanted:
			_stream_packed.erase(path)
			return
	for id in state.nearby_rooms():
		var visual: Dictionary=room_visuals[id]
		if visual.art!=null:continue
		var path: String=state.layout.rooms[id].definition.scene_path
		if not _stream_packed.has(path):continue
		visual.node.free()
		visual.fog.free()
		room_visuals.erase(id)
		_build_castle(id,_stream_packed[path])
		streamed_instances+=1
		return

func door_closed(room_id: int, neighbor: int) -> bool:
	return neighbor<0 or not state.can_pass(room_id,neighbor) or (state.locked() and state.current==room_id)

func _room_type(kind: String) -> String:
	match kind:
		"boss": return "女皇 BOSS"
		"stairs": return "楼梯间"
		"event": return "事件"
		"shop": return "商店"
		"spawn": return "卧室"
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
	var previous_position := Vector2(state.player_x,state.player_z)
	var previous_room := state.current
	var requested_movement := Vector2.ZERO
	_waiting_for_room=false
	if focused and not minimap_mode:
		var horizontal := float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
		var depth := float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
		var movement := Vector2(horizontal,depth).limit_length()*3.5*minf(delta,0.1)
		requested_movement = movement
		if not is_zero_approx(movement.x):
			var direction := 1 if movement.x>0 else -1
			var destination := state.neighbor(direction)
			var door := state.definition().door(direction)
			var local := state.local_position()
			if destination>=0 and room_visuals[destination].art==null and absf(local.y-door.y)<state.definition().door_width/2 and direction*(local.x+movement.x-door.x)>=0:
				# On slow disks keep rendering and input responsive rather than blocking load().
				movement.x=direction*maxf(0.0,direction*(door.x-local.x)-.02)
				_waiting_for_room=true
		if not movement.is_zero_approx():state.move(movement.x,movement.y)
	if is_instance_valid(actor_visual):
		var actual_movement := Vector2(state.player_x,state.player_z)-previous_position
		if state.current!=previous_room: actual_movement=requested_movement
		actor_visual.update_locomotion(actual_movement,delta)
	_sync()
	_pump_room_stream()
	_update_camera(1.0-exp(-delta*(room_transition_speed if not outgoing_rooms.is_empty() else camera_follow_speed)))
	if not minimap_mode and not outgoing_rooms.is_empty() and camera.position.distance_to(_camera_target())<0.025:
		outgoing_rooms.clear()

func _camera_target() -> Vector3:
	var spec := state.definition()
	var progress := clampf((state.local_position().x-spec.floor_bounds.position.x)/spec.floor_bounds.size.x,0.0,1.0)
	var visual: Dictionary = room_visuals[state.current]
	return (visual.camera_left as Vector3).lerp(visual.camera_right,progress)+Vector3(state.room().column*W,state.room().floor*CastleGenerator.FLOOR_HEIGHT+(state.player_height*.25 if state.room().kind=="stairs" else 0),0)

func _snap_camera() -> void:
	if is_instance_valid(camera): _update_camera()
	if not minimap_mode:outgoing_rooms.clear()

func _update_camera(weight: float = 1.0) -> void:
	if not minimap_mode:
		var spec := state.definition()
		camera.position = camera.position.lerp(_camera_target(),weight)
		camera.rotation_degrees = camera.rotation_degrees.lerp(Vector3(spec.camera_pitch,0,0),weight)
		camera.fov = lerpf(camera.fov,spec.camera_fov,weight)
		# Carry the room's atmosphere across the same camera easing instead of flashing.
		var target_environment: Environment = room_visuals[state.current].environment
		for property in ["ambient_light_color","ambient_light_energy","background_color","fog_light_color","fog_light_energy","fog_density","tonemap_exposure","glow_intensity","glow_bloom","ssao_intensity","volumetric_fog_density","volumetric_fog_albedo","volumetric_fog_emission","volumetric_fog_emission_energy","volumetric_fog_length","volumetric_fog_anisotropy"]:
			var destination: Variant = target_environment.get(property)
			if property=="fog_density" and not target_environment.fog_enabled: destination = 0.0
			if property=="volumetric_fog_density" and not target_environment.volumetric_fog_enabled: destination=0.0
			environment.environment.set(property,lerp(environment.environment.get(property),destination,weight))
	else:
		var aspect := maxf(1.0,size.x/maxf(1.0,size.y))
		camera.size = maxf(state.layout.get("floors",1)*CastleGenerator.FLOOR_HEIGHT+2,(state.layout.width*W+2)/aspect) if state.overview else 10.0
		var middle: float = (state.layout.width-1)*W/2
		camera.position = Vector3(middle if state.overview else state.room().column*W,2+((state.layout.get("floors",1)-1)*CastleGenerator.FLOOR_HEIGHT/2 if state.overview else state.room().floor*CastleGenerator.FLOOR_HEIGHT),45)

func _sync() -> void:
	if not is_instance_valid(actor): return
	_refresh_loaded_rooms()
	if minimap_mode:
		for link in stair_links:
			link.node.visible=state.room_visibility(link.lower)>0 and state.room_visibility(link.upper)>0
	elif has_node("MinimapFrame") and _map_expanded!=state.overview:
		_map_expanded=state.overview
		var frame=get_node("MinimapFrame")
		frame.anchor_left=.06 if _map_expanded else .73
		frame.anchor_right=.94 if _map_expanded else .985
		frame.anchor_top=.06 if _map_expanded else .025
		frame.anchor_bottom=.94 if _map_expanded else .20
	actor.position = Vector3(state.player_x,state.room().floor*CastleGenerator.FLOOR_HEIGHT+(state.player_height if state.room().kind=="stairs" or not minimap_mode else 0),0.3 if minimap_mode else state.player_z)
	if displayed_room!=state.current:
		var first_room := displayed_room<0
		if not first_room and not minimap_mode:
			if not outgoing_rooms.has(displayed_room): outgoing_rooms.append(displayed_room)
		displayed_room = state.current
		if not minimap_mode:
			if first_room: environment.environment = room_visuals[state.current].environment.duplicate()
			else:
				var target: Environment=room_visuals[state.current].environment
				for flag in ["fog_enabled","volumetric_fog_enabled","glow_enabled","ssao_enabled"]:
					if target.get(flag):environment.environment.set(flag,true)
			if room_visuals[state.current].filter:paper_rect.material=room_visuals[state.current].filter
		if first_room: _snap_camera()
	for entry in state.layout.rooms:
		var visual: Dictionary = room_visuals[entry.id]
		var visibility := state.room_visibility(entry.id)
		visual.node.visible = visibility==2 if minimap_mode else entry.id==state.current or outgoing_rooms.has(entry.id)
		visual.fog.visible = minimap_mode and visibility==1
		var done: bool = entry.get("completed",false) if entry.kind in ["event","shop"] else entry.cleared
		visual.marker.visible = entry.kind not in ["spawn","stairs"] and (entry.kind=="shop" or not done)
		if entry.kind in ["encounter","boss"] and entry.triggered: visual.marker.visible = false
		for door in door_leaves if entry.id==state.current else []:
			if door.room!=entry.id: continue
			var closed := door_closed(door.room,door.neighbor)
			if door.get("initialized",false) and door.closed==closed:continue
			door.initialized=true
			door.closed = closed
			door.hinge.rotation.y = 0 if door.closed else door.direction*deg_to_rad(100)
			door.sign.text = "封闭" if door.neighbor<0 else ("战斗中锁定" if door.closed else ("返回" if door.direction<0 else "下一间 →"))
	var action := state.available_interaction()
	var message := "WASD / 方向键 四向移动 · 从门口进入下一间 · Tab 地图"
	if not action.is_empty():
		message = ("F 开始战前对话" if action.type=="battle" else "F "+_room_type(state.room().kind))
	elif state.room().kind=="stairs":message="沿前侧楼梯上行 → 平台转身 → 后侧楼梯到达上层 · WASD 移动"
	elif state.locked(): message = "完成战斗后出口解锁 · 靠近中央标记按 F"
	elif state.room().kind=="spawn": message = "从床左侧绕到床后，走向右门 · WASD 四向移动"
	if _waiting_for_room:message="正在准备下一间房间…"
	var prompt := message if not minimap_mode and (not action.is_empty() or _waiting_for_room) else ""
	if interaction_label.text!=prompt:interaction_label.text=prompt
	if _last_hint!=message:
		_last_hint=message
		hint_changed.emit(message)

func _exit_tree() -> void:
	# Finish owned requests before resource shutdown; never wait on them during play.
	for path in _stream_requests:
		ResourceLoader.load_threaded_get(path)
	_stream_requests.clear()

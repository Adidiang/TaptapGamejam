extends SceneTree
## Offline authoring utility. The saved rooms contain editable native nodes, no generator dependency.
const OUT = "res://art/room_studies/"
var meshes: Dictionary = {}
var room: Node3D
var shell: Node3D
var furniture: Node3D
var details: Node3D

func _initialize() -> void:
	call_deferred("build")

func collect(node: Node) -> void:
	if node is MeshInstance3D:
		meshes[String(node.name)] = node.mesh
	for child in node.get_children(): collect(child)

func group(title: String) -> Node3D:
	var node = Node3D.new()
	node.name = title
	room.add_child(node)
	return node

func part(parent: Node3D, key: String, pos: Vector3, yaw: float = 0.0, size: Vector3 = Vector3.ONE) -> Node3D:
	assert(meshes.has(key), "Missing asset: " + key)
	var pivot = Node3D.new()
	pivot.name = key
	parent.add_child(pivot)
	pivot.position = pos
	pivot.rotation_degrees.y = yaw
	pivot.scale = size
	var mesh = MeshInstance3D.new()
	mesh.name = "Model"
	mesh.mesh = meshes[key]
	var bounds = mesh.mesh.get_aabb()
	mesh.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	pivot.add_child(mesh)
	return pivot

func light(parent: Node3D, pos: Vector3, color: Color, energy: float, radius: float) -> void:
	var lamp = OmniLight3D.new()
	lamp.name = "WarmLight" if color.r > color.b else "CoolLight"
	lamp.position = pos
	lamp.light_color = color
	lamp.light_energy = energy
	lamp.omni_range = radius
	lamp.omni_attenuation = 1.3
	lamp.shadow_enabled = true
	parent.add_child(lamp)

func candle(pos: Vector3, size: float = 0.5) -> void:
	part(details,"candlestick_03",pos,0,Vector3.ONE*size)
	light(details,pos+Vector3(0,0.82*size,0),Color("ffb85d"),0.65,3.0)

func base(title: String, wood: bool) -> void:
	room = Node3D.new()
	room.name = title
	room.set_meta("purpose", "Standalone art study. Not connected to gameplay.")
	room.set_meta("footprint", "10 x 7; forward walkway z=1.0; side portals x=+/-5")
	shell = group("Architecture")
	furniture = group("Furniture")
	details = group("SetDressing")
	for x in [-3.75,-1.25,1.25,3.75]:
		for z in [-1.75,1.75]:
			part(shell,"floor_wood_01" if wood else "floor_pavements_01",Vector3(x,-0.17787 if wood else 0.0,z),0,Vector3(0.625,1,0.875))
	for x in [-3.3333,0.0,3.3333]:
		part(shell,"wall_first_floor_01",Vector3(x,0,-3.5),-90,Vector3(1,1,0.83333))
	for x in [-5.0,5.0]:
		part(shell,"wall_first_floor_01",Vector3(x,0,-2.5),0 if x<0 else 180,Vector3(1,1,0.5))
		part(shell,"door_arch_01",Vector3(x,0,0.7),0 if x<0 else 180,Vector3(1,1,1.25))
		part(shell,"pillar_floor_01",Vector3(x,0,-3.5))
		part(shell,"pillar_floor_01",Vector3(x,0,-1.35))
	for x in [-1.67,1.67]:
		part(shell,"pillar_floor_01",Vector3(x,0,-3.35),0,Vector3(0.8,1,0.8))
	for x in [-3.6,3.6]:
		part(details,"candlestick_wall_01",Vector3(x,2.2,-3.05),-90)
		light(details,Vector3(x,2.85,-2.6),Color("ffbc73"),0.85,5.5)
	var preview = group("PreviewRig")
	var env = WorldEnvironment.new()
	env.name = "Environment"
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("101923")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("acb5cf")
	env.environment.ambient_light_energy = 0.36
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	preview.add_child(env)
	var sun = DirectionalLight3D.new()
	sun.name = "SoftFill"
	sun.rotation_degrees = Vector3(-55,-25,0)
	sun.light_color = Color("c3d4ea")
	sun.light_energy = 0.45
	sun.shadow_enabled = true
	preview.add_child(sun)
	var camera = Camera3D.new()
	camera.name = "PreviewCamera"
	camera.fov = 30
	camera.position = Vector3(0,10.6,17.8)
	camera.rotation_degrees.x = -27
	camera.current = true
	preview.add_child(camera)
	light(preview,Vector3(0,5,1),Color("ffcf96"),0.7,12)
	var anchors = group("FutureGameplayAnchors")
	for item in [["LeftDoor",Vector3(-5,0,0.7)],["RightDoor",Vector3(5,0,0.7)],["Interaction",Vector3(0,0,1.0)],["Spawn",Vector3(0,0,2.5)]]:
		var marker = Marker3D.new()
		marker.name = item[0]
		marker.position = item[1]
		anchors.add_child(marker)

func table_set(pos: Vector3, angle: float, long_table: bool = false) -> void:
	var table = part(furniture,"table_rectangle_02" if long_table else "table_round_01",pos,angle)
	var top = 1.16 if long_table else 1.11
	for dx in [-1.2,1.2]:
		part(furniture,"chair_01",pos+Vector3(dx,0,0.1),90 if dx<0 else -90)
	part(furniture,"chair_02",pos+Vector3(0,0,-1.05))
	candle(pos+Vector3(0,top,0),0.5)
	part(details,"bottle_02",pos+Vector3(0.32,top,-0.22),15,Vector3.ONE*0.8)
	part(details,"tankard_01",pos+Vector3(-0.37,top,0.22))
	part(details,"plate_metal_01",pos+Vector3(0.38,top,0.28),0,Vector3.ONE*0.75)

func battle() -> void:
	base("BattleRoom",false)
	part(details,"rug_long_red_01",Vector3(0,0.025,1.7),0,Vector3(1.05,1,0.45))
	table_set(Vector3(-2.8,0,-1.75),-8)
	table_set(Vector3(2.8,0,-1.75),8)
	table_set(Vector3(0,0,-0.8),90,true)
	part(details,"banner_03",Vector3(0,1.6,-3.16),0,Vector3.ONE*0.7)
	part(details,"shield_01",Vector3(0,2.4,-2.98),0,Vector3.ONE*0.7)
	part(furniture,"barrel_medium_01",Vector3(-4.3,0,-2.55))
	part(furniture,"barrel_small_01",Vector3(4.35,0,-2.55))
	part(details,"chandelier_01",Vector3(0,3.5,-0.5),0,Vector3.ONE*0.65)
	light(details,Vector3(0,3.9,-0.5),Color("ffc47b"),1.4,7)
	save_room("battle_room")

func event_room() -> void:
	base("EventRoom",true)
	part(details,"rug_round_green",Vector3(0,0.02,-0.65),0,Vector3.ONE*0.78)
	for x in [-2.8,2.8]:
		part(furniture,"bookshelf_01" if x<0 else "bookshelf_02",Vector3(x,0,-2.93))
		for y in [0.42,1.1,1.82,2.45]:
			part(details,"book_for_shelf_06",Vector3(x-0.38,y,-2.86),0,Vector3.ONE*0.85)
			part(details,"book_for_shelf_08",Vector3(x+0.38,y,-2.86),0,Vector3.ONE*0.8)
	part(details,"hanging_red_01",Vector3(0,0.65,-3.03),-90,Vector3(1,0.85,1.6))
	part(furniture,"table_rectangle_low_01",Vector3(0,0,-1.25),90,Vector3(1.2,1,1))
	part(furniture,"chest_01",Vector3(0,0.63,-1.25),0,Vector3.ONE*0.85)
	part(details,"bookpile_02",Vector3(-0.9,0.63,-1.15),20,Vector3.ONE*0.7)
	part(furniture,"candlestick_01",Vector3(-1.55,0,-1.55),0,Vector3.ONE*0.8)
	part(furniture,"candlestick_01",Vector3(1.55,0,-1.55),0,Vector3.ONE*0.8)
	light(details,Vector3(0,1.8,-0.7),Color("88d9bf"),1.15,4)
	for x in [-1.55,1.55]: light(details,Vector3(x,1.6,-1.55),Color("ffb763"),1.1,4)
	part(furniture,"table_round_low_01",Vector3(-3.65,0,-0.3),0,Vector3.ONE*0.7)
	part(details,"bookpile_01",Vector3(-3.65,0.424,-0.3),-15,Vector3.ONE*0.8)
	part(furniture,"chair_01",Vector3(-4.0,0,-1.25),155)
	part(furniture,"trunk_01",Vector3(3.7,0,-0.5),-15)
	part(details,"painting_02",Vector3(0,2.4,-2.8),0,Vector3.ONE*0.7)
	save_room("event_room")

func shop() -> void:
	base("ShopRoom",true)
	for x in [-1.8,0.0,1.8]:
		part(furniture,"bar_foot_01",Vector3(x,0,-0.7),-90,Vector3(1,1,0.85))
	part(furniture,"bar_counter_01",Vector3(-1.35,1.41,-0.7),90,Vector3(1.15,1,0.68))
	part(furniture,"bar_counter_01",Vector3(1.35,1.41,-0.7),90,Vector3(1.15,1,0.68))
	for x in [-2.4,0.0,2.4]:
		part(furniture,"wall_shelf_01",Vector3(x,1.8,-2.95),-90,Vector3(1,1,0.72))
		for offset in [-0.72,-0.24,0.24,0.72]:
			part(details,"bottle_02" if offset<0 else "bottle_04",Vector3(x+offset,2.43,-2.85),0,Vector3.ONE*0.85)
	for x in [-1.8,0.0,1.8]:
		part(furniture,"chair_02",Vector3(x,0,0.25))
		part(details,"tankard_01",Vector3(x,1.65,-0.4))
		part(details,"bottle_01",Vector3(x+0.25,1.65,-0.95))
	candle(Vector3(-2.2,1.65,-0.65),0.7)
	candle(Vector3(2.2,1.65,-0.65),0.7)
	for x in [-4.0,4.0]:
		part(furniture,"barrel_medium_01",Vector3(x,0,-2.55))
		part(furniture,"barrel_small_01",Vector3(x+0.2,0,-1.15),20)
	part(furniture,"crate_open_01",Vector3(3.85,0,0.1),-12,Vector3.ONE*0.8)
	part(details,"bread_02",Vector3(3.85,0.65,0.1))
	part(details,"rug_long_red_01",Vector3(0,0.025,1.7),0,Vector3(0.85,1,0.4))
	part(details,"banner_04",Vector3(0,2.5,-3.0),0,Vector3.ONE*0.55)
	save_room("shop_room")

func own(node: Node) -> void:
	for child in node.get_children():
		child.owner = room
		own(child)

func save_room(filename: String) -> void:
	own(room)
	var packed = PackedScene.new()
	assert(packed.pack(room)==OK)
	assert(ResourceSaver.save(packed,OUT+filename+".tscn")==OK)
	print("SAVED ",filename," nodes=",room.find_children("*","",true,false).size())
	room.free()

func build() -> void:
	if FileAccess.get_file_as_string(OUT+"battle_room.tscn").contains("room_art_template.gd"):
		push_error("Rooms are now editable gameplay templates. Edit the .tscn files directly; rebuilding would overwrite authored changes.")
		quit(1)
		return
	var source = load("res://art/tavern_library/tavern_parts.gltf").instantiate()
	collect(source)
	DirAccess.make_dir_recursive_absolute("res://art/tavern_library/meshes")
	for key in meshes:
		var mesh = meshes[key]
		var path = "res://art/tavern_library/meshes/"+key+".res"
		assert(ResourceSaver.save(mesh,path)==OK)
		mesh.take_over_path(path)
	battle()
	event_room()
	shop()
	source.free()
	quit()

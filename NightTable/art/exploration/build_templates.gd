extends SceneTree
## One-time authoring utility. Do not run over artist-edited room templates.
const BASE := "res://art/exploration/"
func _initialize(): call_deferred("build")
func box(parent: Node3D, name_value: String, dimensions: Vector3, at: Vector3, color: Color):
	var node := MeshInstance3D.new()
	node.name = name_value
	node.mesh = BoxMesh.new()
	node.mesh.size = dimensions
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1
	node.material_override = mat
	node.position = at
	parent.add_child(node)
	return node
func own(node: Node, scene: Node):
	for child in node.get_children():
		child.owner = scene
		if child.scene_file_path.is_empty(): own(child,scene)
func side_wall(room: Node3D, spec: ExplorationRoomDefinition, direction: int):
	var wall := Node3D.new()
	wall.name = "DoorWall" if direction>0 else "LeftWall"
	room.add_child(wall)
	var door := spec.door(direction)
	var low := door.y-spec.door_width/2
	var high := door.y+spec.door_width/2
	var color := Color("d8d6d3")
	box(wall,"BackPanel",Vector3(0.1,4,low+3),Vector3(door.x+direction*0.05,2,(low-3)/2),color)
	box(wall,"FrontPanel",Vector3(0.1,4,3-high),Vector3(door.x+direction*0.05,2,(high+3)/2),color)
	box(wall,"Lintel",Vector3(0.1,1.4,spec.door_width),Vector3(door.x+direction*0.05,3.3,door.y),color)
func doorway(room: Node3D, spec: ExplorationRoomDefinition, direction: int):
	var door := Node3D.new()
	door.name = "LeftDoor" if direction<0 else "RightDoor"
	var at := spec.door(direction)
	door.position = Vector3(at.x,spec.floor_y,at.y)
	room.add_child(door)
	var hinge := Node3D.new()
	hinge.name = "Hinge"
	hinge.position = Vector3(-direction*0.06,0,-spec.door_width/2)
	door.add_child(hinge)
	box(hinge,"Leaf",Vector3(0.055,2.5,spec.door_width-0.06),Vector3(0,1.25,spec.door_width/2),Color("8c9ba2"))
	for z in [-spec.door_width/2,spec.door_width/2]:
		box(door,"Frame",Vector3(0.18,2.65,0.07),Vector3(0,1.325,z),Color("aaa9a5"))
	box(door,"TopFrame",Vector3(0.18,0.07,spec.door_width),Vector3(0,2.65,0),Color("aaa9a5"))
func build():
	for kind in ["bedroom","whitebox"]:
		var spec: ExplorationRoomDefinition = load(BASE+kind+"_definition.tres")
		var room := Node3D.new()
		room.name = "BedroomRoom" if kind=="bedroom" else "WhiteboxRoom"
		room.set_script(load("res://scripts/exploration_room.gd"))
		room.definition = spec
		if kind=="bedroom":
			var bedroom = load("res://art/bedroom_v2/bedroom.tscn").instantiate()
			bedroom.name = "Bedroom"
			bedroom.rotation_degrees.y = -90
			room.add_child(bedroom)
		else:
			box(room,"Floor",Vector3(9,0.1,6),Vector3(0,0.05,0),Color("858b91"))
			box(room,"BackWall",Vector3(9,4,0.1),Vector3(0,2,-3.05),Color("dedbd5"))
			box(room,"Ceiling",Vector3(9,0.1,6),Vector3(0,4.05,0),Color("c1c2c0"))
			for x in range(-4,5): box(room,"GridX",Vector3(0.012,0.003,6),Vector3(x,0.103,0),Color("a1a5a8"))
			for z in range(-2,3): box(room,"GridZ",Vector3(9,0.003,0.012),Vector3(0,0.103,z),Color("a1a5a8"))
			var env := WorldEnvironment.new()
			env.name = "PreviewEnvironment"
			env.environment = Environment.new()
			env.environment.background_mode = Environment.BG_COLOR
			env.environment.background_color = Color("20252b")
			env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.environment.ambient_light_color = Color.WHITE
			env.environment.ambient_light_energy = 0.5
			room.add_child(env)
			var light := OmniLight3D.new()
			light.name = "RoomFill"
			light.position = Vector3(0,3,1)
			light.light_energy = 0.8
			light.light_specular = 0.0
			light.omni_range = 12
			room.add_child(light)
			var camera := Camera3D.new()
			camera.name = "PreviewCamera"
			camera.position = spec.camera_position
			camera.rotation_degrees.x = spec.camera_pitch
			camera.fov = spec.camera_fov
			camera.current = true
			room.add_child(camera)
			room.add_child(load(BASE+"room_paper_filter.tscn").instantiate())
		for direction in [-1,1]:
			if spec.has_door(direction):
				side_wall(room,spec,direction)
				doorway(room,spec,direction)
		for data in [["Spawn",spec.spawn],["Interaction",spec.interaction],["RightArrival",spec.arrival(1)]]:
			var marker := Marker3D.new()
			marker.name = data[0]
			marker.position = Vector3(data[1].x,spec.floor_y,data[1].y)
			room.add_child(marker)
		own(room,room)
		var packed := PackedScene.new()
		assert(packed.pack(room)==OK)
		assert(ResourceSaver.save(packed,spec.scene_path)==OK)
		room.free()
	quit()

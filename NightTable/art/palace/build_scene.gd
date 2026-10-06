extends SceneTree

func transform_from_rows(rows: Array) -> Transform3D:
	return Transform3D(Basis(Vector3(rows[0][0],rows[1][0],rows[2][0]),Vector3(rows[0][1],rows[1][1],rows[2][1]),Vector3(rows[0][2],rows[1][2],rows[2][2])),Vector3(rows[0][3],rows[1][3],rows[2][3]))

func own_nodes(node: Node, scene: Node):
	for child in node.get_children():
		child.scene_file_path=""
		child.owner=scene
		own_nodes(child,scene)

func _initialize():
	var meta=JSON.parse_string(FileAccess.get_file_as_string("res://art/palace/source_layout.json"))
	var room=Node3D.new()
	room.name="Palace"
	root.add_child(room)
	var layout=load("res://art/palace/palace.glb").instantiate()
	layout.name="Layout"
	room.add_child(layout)
	for light in layout.find_children("*","Light3D",true,false):
		light.get_parent().remove_child(light)
		light.free()
	for camera in layout.find_children("*","Camera3D",true,false): camera.current=false
	var preview=Camera3D.new()
	preview.name="MiddleCamera"
	room.add_child(preview)
	for camera in meta.cameras:
		if camera.name=="摄像机.002":
			preview.transform=transform_from_rows(camera.transform)
			preview.fov=camera.fov
			preview.near=camera.near
			preview.far=camera.far
	preview.current=true
	var lights=Node3D.new()
	lights.name="AdaptedLighting"
	room.add_child(lights)
	for source in meta.lights:
		var light: Light3D
		if source.type=="AREA":
			light=SpotLight3D.new()
			light.spot_range=18.0
			light.spot_angle=80.0
			light.spot_attenuation=0.5
		else:
			light=OmniLight3D.new()
			light.omni_range=12.0
		light.name=source.name
		lights.add_child(light)
		light.transform=transform_from_rows(source.transform)
		light.light_color=Color(source.color[0],source.color[1],source.color[2])
		light.light_energy=source.energy/55.0
		light.light_size=0.5
		light.shadow_enabled=true
	var world=WorldEnvironment.new()
	world.name="PreviewEnvironment"
	world.environment=Environment.new()
	world.environment.background_mode=Environment.BG_COLOR
	world.environment.background_color=Color(0.12,0.12,0.14)
	world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color=Color(0.8,0.82,0.9)
	world.environment.ambient_light_energy=0.5
	world.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	world.environment.ssao_enabled=true
	room.add_child(world)
	own_nodes(room,room)
	var packed=PackedScene.new()
	assert(packed.pack(room)==OK)
	assert(ResourceSaver.save(packed,"res://art/palace/palace.tscn")==OK)
	print("PALACE_SCENE_SAVED")
	quit()

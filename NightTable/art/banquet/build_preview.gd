extends SceneTree
func _initialize(): call_deferred("build")
func pose(rows):
	return Transform3D(Basis(Vector3(rows[0][0],rows[1][0],rows[2][0]),Vector3(rows[0][1],rows[1][1],rows[2][1]),Vector3(rows[0][2],rows[1][2],rows[2][2])).orthonormalized(),Vector3(rows[0][3],rows[1][3],rows[2][3]))
func own(node,scene):
	if node!=scene:
		node.owner=scene
		node.scene_file_path=""
	for child in node.get_children(): own(child,scene)
func build():
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://art/banquet/source_layout.json"))
	var scene=Node3D.new()
	scene.name="Banquet"
	root.add_child(scene)
	var model=load("res://art/banquet/banquet.glb").instantiate()
	model.name="Layout"
	scene.add_child(model)
	for camera in model.find_children("*","Camera3D",true,false): camera.current=false
	var camera=Camera3D.new()
	camera.name="PreviewCamera"
	scene.add_child(camera)
	for o in data.objects:
		if o.name==data.camera:
			camera.transform=pose(o.transform)
			camera.fov=o.fov
		if o.type=="LIGHT":
			var lamp=SpotLight3D.new()
			lamp.name="Adapted_"+o.name.replace(".","_")
			scene.add_child(lamp)
			lamp.transform=pose(o.transform)
			lamp.light_color=Color(o.color[0],o.color[1],o.color[2])
			lamp.light_energy=o.energy*0.006
			lamp.spot_range=22
			lamp.spot_angle=70 if o.kind=="AREA" else 55
			lamp.spot_attenuation=0.8
			lamp.light_size=0.35
			lamp.shadow_enabled=true
	camera.current=true
	var world=WorldEnvironment.new()
	world.name="PreviewEnvironment"
	world.environment=Environment.new()
	world.environment.background_mode=Environment.BG_COLOR
	world.environment.background_color=Color("20232a")
	world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color=Color("c8cbd6")
	world.environment.ambient_light_energy=0.3
	world.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	world.environment.ssao_enabled=true
	scene.add_child(world)
	own(scene,scene)
	var packed=PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,"res://art/banquet/banquet.tscn")==OK)
	print("BANQUET_PREVIEW_BUILT")
	quit()

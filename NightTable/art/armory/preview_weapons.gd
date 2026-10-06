extends SceneTree
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1800,1100)
	var scene=Node3D.new();root.add_child(scene)
	var lib=load("res://art/armory/weapons/weapons.glb").instantiate()
	var cat=JSON.parse_string(FileAccess.get_file_as_string("res://art/armory/weapons/catalog.json"))
	for i in cat.size():
		var entry=cat[i]
		var obj=lib.get_node(entry.id).duplicate()
		scene.add_child(obj)
		obj.scale=Vector3.ONE*1.5/maxf(maxf(entry.size[0],entry.size[1]),entry.size[2])
		obj.position=Vector3((i%8)*2.3,0,(i/8)*3.1)
		var label=Label3D.new();label.text=entry.id;label.font_size=48;label.pixel_size=.007
		label.position=obj.position+Vector3(0,0,.75);label.rotation_degrees.x=-55;scene.add_child(label)
	lib.free()
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color(.15,.18,.21);env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.8;scene.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-60,-20,0);scene.add_child(sun)
	var cam=Camera3D.new();scene.add_child(cam);cam.position=Vector3(8,18,22);cam.look_at(Vector3(8,0,4.5));cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=20
	for i in 30:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("F:/gamejam/outputs/armory/weapon_catalog.png")
	scene.queue_free();await process_frame;await process_frame;quit()

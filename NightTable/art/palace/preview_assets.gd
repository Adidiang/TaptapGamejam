extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var palace=load("res://art/palace/palace.tscn").instantiate()
	for mesh in palace.find_children("*","MeshInstance3D",true,false):
		print("PALACE_BOUNDS ",mesh.name," ",mesh.transform*mesh.get_aabb())
	palace.free()
	root.size=Vector2i(2000,1400)
	var stage=Node3D.new()
	root.add_child(stage)
	var extra="--extra" in OS.get_cmdline_user_args()
	var prefix="extra_" if extra else ""
	var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://art/palace/fill_assets/"+prefix+"catalog.json"))
	var sources={}
	for file in ["courtyard","office"]:
		var lib=load("res://art/palace/fill_assets/"+prefix+file+".glb").instantiate()
		for child in lib.get_children(): sources[String(child.name)]=child.duplicate()
		lib.free()
	for i in catalog.size():
		var item=catalog[i]
		var obj=sources[item.id]
		stage.add_child(obj)
		var sz=item.size
		var factor=1.8/maxf(maxf(sz[0],sz[1]),sz[2])
		obj.scale=Vector3.ONE*factor
		obj.position=Vector3((i%8)*2.5,0,(i/8)*3.1)
		var label=Label3D.new()
		label.text=item.id
		label.font_size=60
		label.pixel_size=.008
		label.position=obj.position+Vector3(0,0,.65)
		label.rotation_degrees.x=-55
		stage.add_child(label)
	var env=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color(.18,.2,.24)
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color.WHITE
	env.environment.ambient_light_energy=.8
	stage.add_child(env)
	var sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-60,-30,0)
	stage.add_child(sun)
	var cam=Camera3D.new()
	stage.add_child(cam)
	cam.position=Vector3(8.8,23,24)
	cam.look_at(Vector3(8.8,0,8))
	cam.projection=Camera3D.PROJECTION_ORTHOGONAL
	cam.size=23
	for i in 30:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("F:/gamejam/outputs/palace/"+prefix+"assets.png")
	stage.queue_free()
	await process_frame
	await process_frame
	quit()

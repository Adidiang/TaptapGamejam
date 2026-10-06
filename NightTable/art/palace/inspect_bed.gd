extends SceneTree
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1400,1000)
	var stage=Node3D.new()
	root.add_child(stage)
	var bed=load("res://art/palace/empress_bed.glb").instantiate()
	stage.add_child(bed)
	var bounds=AABB()
	var first=true
	for m in bed.find_children("*","MeshInstance3D",true,false):
		var b=m.global_transform*m.get_aabb()
		bounds=b if first else bounds.merge(b)
		first=false
		print("NEW_MESH ",m.name," bounds=",b," surfaces=",m.mesh.get_surface_count())
	print("NEW_BOUNDS ",bounds)
	var palace=load("res://art/palace/palace.tscn").instantiate()
	var old=palace.get_node("Layout/tripo_node_c93fc015-e3fe-4871-9491-cdf6ac717d70")
	print("OLD_LOCAL ",old.get_aabb()," TRANSFORM ",old.transform)
	palace.free()
	var env=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color(.13,.14,.18)
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color.WHITE
	env.environment.ambient_light_energy=.65
	stage.add_child(env)
	var sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-40,-30,0)
	stage.add_child(sun)
	var cam=Camera3D.new()
	stage.add_child(cam)
	var center=bounds.get_center()
	var radius=bounds.size.length()
	cam.position=center+Vector3(.7,.35,1.2)*radius
	cam.look_at(center)
	cam.far=10000
	cam.near=.01
	for i in 30:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("F:/gamejam/outputs/palace/new_bed_asset.png")
	stage.queue_free()
	await process_frame
	await process_frame
	quit()

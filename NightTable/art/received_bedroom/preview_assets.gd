extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	root.size=Vector2i(1500,1500)
	root.content_scale_size=Vector2i.ZERO
	var stage=Node3D.new()
	root.add_child(stage)
	var env=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color(0.18,0.2,0.23)
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color.WHITE
	env.environment.ambient_light_energy=0.7
	stage.add_child(env)
	var light=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-25,-25,0)
	stage.add_child(light)
	var camera=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=15.5
	camera.position=Vector3(6.25,-5,20)
	stage.add_child(camera)
	var rows=JSON.parse_string(FileAccess.get_file_as_string("res://art/received_bedroom/dressing_assets/catalog.json"))
	for i in range(rows.size()):
		var row=rows[i]
		var obj=load("res://art/received_bedroom/dressing_assets/"+row.id+".glb").instantiate()
		var s=1.7/max(row.size[0],max(row.size[1],row.size[2]))
		obj.scale=Vector3.ONE*s
		if row.id.begins_with("0_"):obj.rotation_degrees.y=-65
		obj.position=Vector3((i%6)*2.5,-(i/6)*2.4,0)
		stage.add_child(obj)
		var label=Label3D.new()
		label.text=row.id+" "+row.name
		label.font_size=24
		label.pixel_size=0.0028
		label.position=obj.position+Vector3(0,-0.24,1)
		stage.add_child(label)
	for i in range(15):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("F:/gamejam/exports/dressing/atlas.png")
	quit()

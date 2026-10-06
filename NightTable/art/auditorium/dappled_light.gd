extends SceneTree
func _initialize(): call_deferred("tune")
func tune():
	var scene=load("res://art/auditorium/auditorium.tscn").instantiate()
	root.add_child(scene)
	# Separate floor fill from stage lighting so the aisle retains dark intervals.
	var floor_mesh=scene.get_node("Layout/立方体")
	floor_mesh.layers=8
	for light in scene.find_children("*","Light3D",true,false):
		light.light_cull_mask=1
		if str(light.name).begins_with("WindowPool_"): light.light_energy=0
	var old=scene.get_node_or_null("AisleWindowLight")
	if old: old.free()
	var group=Node3D.new()
	group.name="AisleWindowLight"
	scene.add_child(group)
	group.owner=scene
	group.rotation.y=PI/2
	var gradient=Gradient.new()
	gradient.offsets=PackedFloat32Array([0,.5,.8,1])
	gradient.colors=PackedColorArray([Color.WHITE,Color.WHITE,Color(.35,.35,.35),Color.BLACK])
	var projector=GradientTexture2D.new()
	projector.gradient=gradient
	projector.width=256
	projector.height=256
	projector.fill=GradientTexture2D.FILL_RADIAL
	projector.fill_from=Vector2(.5,.5)
	projector.fill_to=Vector2(1,.5)
	for i in 3:
		var n=SpotLight3D.new()
		n.name="SoftWindowPatch_%d"%i
		group.add_child(n)
		n.owner=scene
		var z=-7.0+i*3.6
		n.position=Vector3(-4.8,6,z-1.7)
		n.look_at(group.to_global(Vector3(.1,.08,z)))
		n.light_color=Color(["c2e7f5","e8d5ec","d2e9df"][i])
		n.light_energy=12
		n.light_cull_mask=8
		n.light_projector=projector
		n.light_volumetric_fog_energy=.15
		n.spot_angle=17
		n.spot_range=13
		n.spot_attenuation=.5
		n.light_size=.4
		n.shadow_enabled=true
	var packed=PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,"res://art/auditorium/auditorium.tscn")==OK)
	print("DAPPLED_LIGHT_SAVED")
	quit()

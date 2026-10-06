extends SceneTree
func _initialize(): call_deferred("tune")
func native(p: Vector3) -> Vector3: return Vector3(p.z,p.y,-p.x)
func spot(group,label,pos,target,color,energy,reach,angle):
	var light=SpotLight3D.new()
	light.name=label
	group.add_child(light)
	light.owner=group.owner
	light.position=native(pos)
	light.look_at(native(target),Vector3.UP)
	light.light_color=Color(color)
	light.light_energy=energy
	light.light_specular=0
	light.light_size=.5
	light.shadow_enabled=true
	light.spot_range=reach
	light.spot_angle=angle
	light.spot_attenuation=.65
func tune():
	var scene=load("res://art/banquet/banquet.tscn").instantiate()
	root.add_child(scene)
	var env=scene.get_node("PreviewEnvironment").environment.duplicate()
	scene.get_node("PreviewEnvironment").environment=env
	env.ambient_light_color=Color("929dbb")
	env.ambient_light_energy=.16
	env.fog_light_color=Color("9c91b8")
	env.fog_light_energy=.35
	env.fog_density=.012
	env.glow_intensity=.85
	env.glow_bloom=.09
	env.ssao_intensity=1.25
	for light in scene.find_children("Adapted*","Light3D",true,false): light.light_energy=0
	for light in scene.find_children("WarmPool*","OmniLight3D",true,false):
		light.light_color=Color("ffb898")
		light.light_energy=2.2
		light.omni_range=3.8
		light.omni_attenuation=.8
	var old=scene.get_node_or_null("BanquetLighting")
	if old: old.free()
	var group=Node3D.new()
	group.name="BanquetLighting"
	scene.add_child(group)
	group.owner=scene
	spot(group,"BlueLilacBackdrop",Vector3(0,4,-3.8),Vector3(0,2.5,-8.4),"b9caff",7,9,48)
	spot(group,"CoolAisle",Vector3(0,4.8,-3),Vector3(0,0,-4.2),"87baff",7,8,40)
	spot(group,"RoseTableLeft",Vector3(-2.3,4.5,-2),Vector3(-2.8,1,-4.2),"ffb6c9",4.2,7,48)
	spot(group,"PeachTableRight",Vector3(2.3,4.5,-2),Vector3(2.8,1,-4.2),"ffd0b5",4.2,7,48)
	spot(group,"SoftFrontFill",Vector3(0,3,3),Vector3(0,1,-4),"d9d4f2",1.4,12,65)
	# Keep this room's lighting from spilling into the bedroom during transitions.
	for mesh in scene.find_children("*","MeshInstance3D",true,false): mesh.layers=4
	for light in scene.find_children("*","Light3D",true,false): light.light_cull_mask=4
	var packed=PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,"res://art/banquet/banquet.tscn")==OK)
	print("BANQUET_LIGHTING_SAVED")
	quit()

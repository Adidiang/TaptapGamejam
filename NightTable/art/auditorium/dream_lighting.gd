extends SceneTree
var scene
var group
func _initialize(): call_deferred("tune")
func spot(label,pos,target,color,energy,angle,reach):
	var n=SpotLight3D.new()
	n.name=label
	group.add_child(n)
	n.owner=scene
	n.position=pos
	n.look_at(group.to_global(target))
	n.light_color=Color(color)
	n.light_energy=energy
	n.spot_range=reach
	n.spot_angle=angle
	n.spot_attenuation=.6
	n.light_size=.5
	n.light_volumetric_fog_energy=.6
	n.shadow_enabled=true
func tune():
	scene=load("res://art/auditorium/auditorium.tscn").instantiate()
	root.add_child(scene)
	var old=scene.get_node_or_null("DreamLighting")
	if old: old.free()
	group=Node3D.new()
	group.name="DreamLighting"
	scene.add_child(group)
	group.owner=scene
	group.rotation.y=PI/2
	var env=scene.get_node("PreviewEnvironment").environment.duplicate()
	scene.get_node("PreviewEnvironment").environment=env
	env.ambient_light_color=Color("a4bfc5")
	env.ambient_light_energy=.24
	env.glow_enabled=true
	env.glow_intensity=1.05
	env.glow_bloom=.09
	env.glow_hdr_threshold=.95
	env.volumetric_fog_enabled=true
	env.volumetric_fog_density=.012
	env.volumetric_fog_albedo=Color("bac8db")
	env.volumetric_fog_emission=Color("607284")
	env.volumetric_fog_emission_energy=.08
	env.volumetric_fog_anisotropy=.45
	env.volumetric_fog_length=30
	var film=scene.get_node("DreamGrade/DreamFilm").material.duplicate()
	film.shader=load("res://art/auditorium/hall_grade.gdshader")
	film.set_shader_parameter("softness",.13)
	film.set_shader_parameter("vignette_strength",.2)
	scene.get_node("DreamGrade/DreamFilm").material=film
	# The circular stained glass is a separate mesh; retain its painted color texture.
	for n in scene.get_node("Layout").get_children():
		if str(n.name).begins_with("tripo_node_6547"):
			for i in n.mesh.get_surface_count():
				var m=n.get_active_material(i).duplicate()
				if m is StandardMaterial3D:
					m.emission_enabled=true
					m.emission_texture=m.albedo_texture
					m.emission=Color.WHITE
					m.emission_operator=BaseMaterial3D.EMISSION_OP_MULTIPLY
					m.emission_energy_multiplier=.85
					n.set_surface_override_material(i,m)
	spot("RoseHeartHalo",Vector3(0,7,-2),Vector3(0,5,-8),"ffc7df",5,44,15)
	spot("MintWindowWash",Vector3(-4,10,-4),Vector3(0,9,-10),"bcf4ec",6,40,13)
	spot("LilacStageEdge",Vector3(5,6,-4),Vector3(0,2,-8),"c9c1ff",4,42,13)
	for i in 4:
		var z=-7+i*2.4
		spot("WindowPool_%d"%i,Vector3(-5.8,5.7,z-2),Vector3(.1,.05,z),["b9e2f6","f4cbdc","c4efe1","d1c9ff"][i],5.5,16,12)
	var packed=PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,"res://art/auditorium/auditorium.tscn")==OK)
	print("DREAM_LIGHTING_SAVED")
	quit()


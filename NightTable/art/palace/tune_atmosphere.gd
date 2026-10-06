extends SceneTree
var room:Node3D
var rig:Node3D
func own(node:Node):
	for child in node.get_children():
		child.scene_file_path=""
		child.owner=room
		own(child)
func spot(label:String,pos:Vector3,target:Vector3,color:Color,energy:float,angle:float):
	var light=SpotLight3D.new()
	light.name=label
	rig.add_child(light)
	light.position=pos
	light.basis=Basis.looking_at(target-pos,Vector3.UP)
	light.light_color=color
	light.light_energy=energy
	light.spot_angle=angle
	light.spot_range=14
	light.spot_attenuation=1.2
	light.light_size=.3
	light.shadow_enabled=true
	light.light_volumetric_fog_energy=.35
func pool(label:String,pos:Vector3,color:Color,energy:float,radius:float):
	var light=OmniLight3D.new()
	light.name=label
	rig.add_child(light)
	light.position=pos
	light.light_color=color
	light.light_energy=energy
	light.omni_range=radius
	light.light_size=.18
	light.shadow_enabled=true
	light.light_volumetric_fog_energy=.25
func _initialize():
	room=load("res://art/palace/palace.tscn").instantiate()
	root.add_child(room)
	for key in ["AtmosphereLighting","DreamGrade"]:
		if room.has_node(key):
			var old=room.get_node(key)
			room.remove_child(old)
			old.free()
	rig=Node3D.new()
	rig.name="AtmosphereLighting"
	room.add_child(rig)
	for light in room.get_node("AdaptedLighting").get_children():light.light_energy=.22
	var env:Environment=room.get_node("PreviewEnvironment").environment.duplicate()
	room.get_node("PreviewEnvironment").environment=env
	env.ambient_light_color=Color(.55,.64,.72)
	env.ambient_light_energy=.30
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled=true
	env.ssao_radius=.45
	env.ssao_intensity=1.35
	env.glow_enabled=true
	env.glow_intensity=.85
	env.glow_bloom=.12
	env.glow_hdr_threshold=.85
	env.fog_enabled=true
	env.fog_light_color=Color(.46,.52,.61)
	env.fog_light_energy=.35
	env.fog_density=.004
	env.volumetric_fog_enabled=true
	env.volumetric_fog_density=.0045
	env.volumetric_fog_albedo=Color(.65,.68,.78)
	env.volumetric_fog_length=18
	env.volumetric_fog_ambient_inject=.25
	spot("LavenderWindow",Vector3(.7,4.25,3.9),Vector3(-1.2,.3,.3),Color(.73,.68,1),6.0,43)
	spot("RoseHeart",Vector3(.4,4.1,1.5),Vector3(-3,2.3,-.6),Color(1,.61,.78),4.5,48)
	spot("BedSilkRim",Vector3(2.5,3.7,-3.65),Vector3(-1.3,2.2,-2.6),Color(.78,.73,1),1.8,48)
	spot("BedRoseBounce",Vector3(3.5,3.2,.0),Vector3(-1,1.7,-2.4),Color(1,.69,.82),1.7,58)
	spot("ChandelierPearl",Vector3(2.5,5.0,2),Vector3(-.1,4.4,-.75),Color(1,.78,.87),2.5,55)
	spot("FloorMoonPool",Vector3(1.2,3.4,3.95),Vector3(.4,.12,.7),Color(.78,.78,1),3.6,30)
	pool("ChandelierRose",Vector3(-.1,4.45,-.75),Color(1,.67,.78),1.5,4.3)
	pool("LeftCandleGlow",Vector3(-.2,1.85,3.7),Color(1,.73,.49),1.65,2.4)
	pool("BedsideCandleGlow",Vector3(.2,1.85,-3.9),Color(1,.72,.52),1.5,2.5)
	pool("RearMintHaze",Vector3(-2.7,2.6,-3.65),Color(.58,.85,.77),1.15,2.6)
	spot("VanitySoftFill",Vector3(4.5,2.8,-1.4),Vector3(3.4,.9,-1.8),Color(.92,.72,.82),.85,60)
	var grade=load("res://art/exploration/room_paper_filter.tscn").instantiate()
	grade.name="DreamGrade"
	room.add_child(grade)
	var mat:ShaderMaterial=load("res://art/exploration/room_paper_filter.tres").duplicate()
	mat.set_shader_parameter("softness",.26)
	mat.set_shader_parameter("vignette_strength",.30)
	mat.set_shader_parameter("grain_strength",.006)
	mat.set_shader_parameter("fringe",.00065)
	mat.set_shader_parameter("paper_strength",.027)
	assert(ResourceSaver.save(mat,"res://art/palace/dream_profile.tres")==OK)
	grade.get_node("DreamFilm").material=mat
	# Small luminous tips on the single candlesticks, using their actual mesh bounds.
	for container_name in ["Dressing","Enrichment"]:
		for obj in room.get_node(container_name).get_children():
			if obj.get_meta("source_asset","")!="O12":continue
			var flame=MeshInstance3D.new()
			flame.name="CandleFlame"+str(rig.get_child_count())
			var mesh=SphereMesh.new()
			mesh.radius=.012
			mesh.height=.05
			flame.mesh=mesh
			var material=StandardMaterial3D.new()
			material.albedo_color=Color(1,.8,.55)
			material.emission_enabled=true
			material.emission=Color(1,.6,.28)
			material.emission_energy_multiplier=3.0
			flame.material_override=material
			flame.position=obj.position+Vector3(0,obj.scale.y*.47+.016,0)
			rig.add_child(flame)
	own(room)
	var packed=PackedScene.new()
	assert(packed.pack(room)==OK)
	assert(ResourceSaver.save(packed,"res://art/palace/palace.tscn")==OK)
	print("PALACE_ATMOSPHERE_SAVED")
	room.queue_free()
	quit()

extends SceneTree
var scene
var decor
var assets={}
func _initialize(): call_deferred("build")
func own(n): n.owner=scene
func material(color):
	var m=StandardMaterial3D.new()
	m.albedo_color=Color(color)
	m.roughness=.85
	return m
func box(label,pos,size,mat):
	var n=MeshInstance3D.new()
	n.name=label
	n.mesh=BoxMesh.new()
	n.mesh.size=size
	n.material_override=mat
	decor.add_child(n)
	own(n)
	n.position=pos
	return n
func prop(label,asset,pos,size,yaw=0):
	var original=assets[asset]
	var mesh=original.mesh
	var basis=Basis(Vector3.UP,deg_to_rad(yaw))
	var bounds: AABB=Transform3D(basis,Vector3.ZERO)*mesh.get_aabb()
	var scale_v=size/Vector3(maxf(bounds.size.x,.001),maxf(bounds.size.y,.001),maxf(bounds.size.z,.001))
	var n=MeshInstance3D.new()
	n.name=label
	n.mesh=mesh
	n.transform=Transform3D(Basis.from_scale(scale_v)*basis,pos-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*scale_v)
	decor.add_child(n)
	own(n)
	for i in mesh.get_surface_count():
		var mat=original.get_active_material(i)
		if mat is StandardMaterial3D:
			mat=mat.duplicate()
			mat.roughness=.85
			mat.metallic_specular=.2
			n.set_surface_override_material(i,mat)
	return n
func spot(label,pos,target,color,energy,reach,angle):
	var n=SpotLight3D.new()
	n.name=label
	decor.add_child(n)
	own(n)
	n.position=pos
	n.look_at(decor.to_global(target))
	n.light_color=Color(color)
	n.light_energy=energy
	n.spot_range=reach
	n.spot_angle=angle
	n.spot_attenuation=.6
	n.light_size=.45
	n.shadow_enabled=true
func build():
	scene=load("res://art/auditorium/auditorium.tscn").instantiate()
	root.add_child(scene)
	assert(not scene.has_node("HallDressing"))
	var libraries=[]
	for path in ["res://art/banquet/dining_assets/selected.glb","res://art/auditorium/office_assets/selected.glb"]:
		var lib=load(path).instantiate()
		libraries.append(lib)
		for m in lib.find_children("*","MeshInstance3D",true,false): assets[str(m.name)]=m
	print("ASSETS ",assets.keys())
	decor=Node3D.new()
	decor.name="HallDressing"
	scene.add_child(decor)
	own(decor)
	decor.rotation.y=PI/2
	var floor_mat=ShaderMaterial.new()
	floor_mat.shader=load("res://art/auditorium/inlaid_floor.gdshader")
	floor_mat.set_shader_parameter("stone",load("res://art/auditorium/office_assets/stone.png"))
	scene.get_node("Layout/立方体").material_override=floor_mat
	var paper=ShaderMaterial.new()
	paper.shader=load("res://art/auditorium/wallpaper.gdshader")
	paper.set_shader_parameter("wall",load("res://art/auditorium/office_assets/wall.png"))
	for name in ["立方体_003","立方体_004","立方体_002"]: scene.get_node("Layout/"+name).material_override=paper
	var gold=material("bba574")
	var jade=material("6b9588")
	for side in [-1,1]:
		for z in [-9.5,-5.0,-.5]:
			prop("CarvedWainscot","Wainscot",Vector3(side*7.17,.1,z),Vector3(.22,2.6,4.35),side*90)
			prop("OfficeCarvedPanel","CarvedPanel",Vector3(side*7.06,3.15,z),Vector3(.22,5.6,3.6),-side*90)
			prop("HighVelvetDrape","Curtain",Vector3(side*6.85,8.4,z),Vector3(.38,4.4,3.5),side*90)
			prop("WallSconce","WallSconce",Vector3(side*6.55,4.5,z),Vector3(.65,1.1,.65),side*90)
			prop("GoldMedallion","CarvedMedallion",Vector3(side*6.78,6.7,z),Vector3(.2,1.3,1.1),-side*90)
			spot("WallWash",Vector3(side*5.7,7,z+1),Vector3(side*7.2,4,z),"ffd5b5",1.8,7,62)
		for z in [-11.7,-7.3,-2.8,1.8]:
			box("FlutedPilaster",Vector3(side*6.9,6.8,z),Vector3(.5,13.4,.5),jade)
			for y in [1.5,3.0,8.7,12.9]: box("GiltCollar",Vector3(side*6.9,y,z),Vector3(.66,.16,.66),gold)
			prop("ColumnFoot","Pedestal",Vector3(side*6.9,.1,z),Vector3(.85,1.35,.85))
		for y in [2.8,9,13.2]:box("LongCornice",Vector3(side*7.02,y,-4.7),Vector3(.32,.2,15),gold)
		for z in [-7.2,-2.8]:
			prop("AisleCandelabra","StandingCandelabra",Vector3(side*5.85,.1,z),Vector3(.75,2,.75))
			prop("DecorativeVase","Vase",Vector3(side*6.25,1.5,z+.55),Vector3(.65,.95,.6))
			prop("VasePlinth","Pedestal",Vector3(side*6.25,.1,z+.55),Vector3(.8,1.4,.8))
	spot("CentralCoolFill",Vector3(0,8,-1),Vector3(0,2,-9),"b9dbe4",2.8,18,52)
	spot("RoseAisle",Vector3(-3,6,1),Vector3(0,0,-4),"f1d2cc",3,14,40)
	var env=scene.get_node("PreviewEnvironment").environment.duplicate()
	scene.get_node("PreviewEnvironment").environment=env
	env.ambient_light_color=Color("b7cecb")
	env.ambient_light_energy=.32
	env.glow_enabled=true
	env.glow_intensity=.65
	env.glow_bloom=.05
	var filter=load("res://art/exploration/room_paper_filter.tscn").instantiate()
	scene.add_child(filter)
	own(filter)
	var packed=PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,"res://art/auditorium/auditorium.tscn")==OK)
	for lib in libraries: lib.free()
	print("AUDITORIUM_DRESSED")
	quit()


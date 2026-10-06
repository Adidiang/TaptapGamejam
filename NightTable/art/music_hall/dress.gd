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
	decor.add_child(n,true)
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
	decor.add_child(n,true)
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
	decor.add_child(n,true)
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
	scene=load("res://art/music_hall/music_hall.tscn").instantiate()
	root.add_child(scene)
	assert(not scene.has_node("MusicSalon"))
	var libraries=[]
	for path in ["res://art/music_hall/nine_assets/pack0.glb","res://art/music_hall/nine_assets/pack1.glb"]:
		var lib=load(path).instantiate()
		libraries.append(lib)
		for m in lib.find_children("*","MeshInstance3D",true,false):assets[str(m.name)]=m
	decor=Node3D.new()
	decor.name="MusicSalon"
	scene.add_child(decor)
	own(decor)
	decor.rotation.y=PI/2
	var floor_mat=ShaderMaterial.new()
	floor_mat.shader=load("res://art/music_hall/floor.gdshader")
	floor_mat.set_shader_parameter("stone",load("res://art/auditorium/office_assets/stone.png"))
	scene.get_node("Layout/立方体").material_override=floor_mat
	var paper=ShaderMaterial.new()
	paper.shader=load("res://art/music_hall/wallpaper.gdshader")
	paper.set_shader_parameter("wall",load("res://art/auditorium/office_assets/wall.png"))
	for name in ["立方体_003","立方体_004","立方体_002"]:scene.get_node("Layout/"+name).material_override=paper
	var gold=material("8c7852")
	var jade=material("394e49")
	for side in [-1,1]:
		for z in [-10.2,-6.6,-2.9,1.9]:
			prop("CarvedWallPanel","Panel",Vector3(side*7.16,.1,z),Vector3(.24,3.0,3.4),side*90)
			prop("UpperPortrait","Painting",Vector3(side*7.0,4.8,z),Vector3(.24,2.4,1.7),side*90)
		for z in [-11.65,-8.3,-4.8,-1.3,2.8]:
			prop("ArchitecturalColumn","Pillar",Vector3(side*6.94,.1,z),Vector3(.48,9.6,.48))
		for y in [3.2,8.8]:box("GiltCornice",Vector3(side*7.0,y,-4.5),Vector3(.4,.18,15),gold)
		prop("RearLibrary","Bookcase",Vector3(side*6.05,.15,-10.1),Vector3(2.0,5.3,.8))
		prop("CornerSideboard","Sideboard",Vector3(side*6.55,.15,-7.25),Vector3(.9,2.7,2.0),-side*90)
		prop("ForwardLibrary","Bookcase",Vector3(side*6.7,.15,1.65),Vector3(.85,3.9,2.1),-side*90)
		prop("SalonSofa","Sofa",Vector3(side*5.85,.15,-1.5),Vector3(.9,1.3,2.15),-side*90)
		prop("CoffeeTable","Table",Vector3(side*4.65,.15,-1.55),Vector3(.85,.72,1.4))
		prop("TableCandelabra","Candelabra",Vector3(side*4.65,.9,-1.7),Vector3(.42,.8,.42))
		prop("TableBooks","Books",Vector3(side*4.6,.9,-1.2),Vector3(.45,.18,.32))
		for z in [-.1,1.4]:
			prop("AudienceChair","Chair",Vector3(side*3.8,.15,z),Vector3(.72,1.6,.78),180)
		prop("TallClock","Clock",Vector3(side*6.15,.15,-2.7),Vector3(.7,2.65,.65))
		for z in [-8.3,-2.65,2.7]:prop("CornerPlant","Plant",Vector3(side*6.1,.15,z),Vector3(.9,2.15,.85))
		for z in [-7.8,-1.8]:
			prop("HangingChandelier","Chandelier",Vector3(side*4.9,6.4,z),Vector3(1.7,2.6,1.7))
			spot("WarmChandelierPool",Vector3(side*4.9,6.3,z),Vector3(side*4.8,.2,z-.5),"ffd3a6",5,10,48)
		for z in [-10.2,1.6]:
			for y in [.9,1.7,2.5,3.3]:
				for x in [-.48,.15,.65]:
					var p=Vector3(side*6.05+x,y,z+.1)
					if z>0:p=Vector3(side*6.17,y,z+x)
					prop("LibraryVolumes","Books",p,Vector3(.45,.38,.28),0 if z<0 else -side*90)
		spot("RoseLibraryWash",Vector3(side*4.9,5.6,-5),Vector3(side*6.5,2.8,-9.5),"e9bacf",4.5,11,48)
	# Rear panels are behind the original stage; no stage or instrument transforms change.
	for x in [-5.5,-2.75,0,2.75,5.5]:
		prop("StageRearPanelling","Panel",Vector3(x,.9,-11.7),Vector3(2.65,5.4,.22))
		prop("RearCandelabra","Candelabra",Vector3(x,1.0,-10.4),Vector3(.6,1.65,.6))
		prop("RearPilaster","Pillar",Vector3(x,5.8,-11.5),Vector3(.36,5,.36))
	spot("SilverBlueStage",Vector3(-3.5,6,-5),Vector3(0,2,-9.7),"b7d8ef",6,13,48)
	spot("RoseStage",Vector3(4,5,-4),Vector3(0,1,-7),"eed1dc",4.5,12,42)
	spot("PianoRim",Vector3(0,5,-10),Vector3(1,1.7,-6),"ccdfff",7,9,36)
	for light in scene.get_children():
		if light is Light3D and str(light.name).begins_with("Adapted_"):light.light_energy*=.45
	var env=scene.get_node("PreviewEnvironment").environment.duplicate()
	scene.get_node("PreviewEnvironment").environment=env
	env.ambient_light_color=Color("b4c9d0")
	env.ambient_light_energy=.24
	env.glow_enabled=true
	env.glow_intensity=.85
	env.glow_bloom=.04
	env.volumetric_fog_enabled=true
	env.volumetric_fog_density=.006
	env.volumetric_fog_albedo=Color("b3c5cc")
	var film_layer=CanvasLayer.new()
	film_layer.name="MusicGrade"
	scene.add_child(film_layer)
	own(film_layer)
	var film=ColorRect.new()
	film.name="PaperFilm"
	film_layer.add_child(film)
	own(film)
	film.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	film.mouse_filter=Control.MOUSE_FILTER_IGNORE
	film.material=load("res://art/exploration/room_paper_filter.tres").duplicate()
	film.material.set_shader_parameter("softness",.1)
	var packed=PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,"res://art/music_hall/music_hall.tscn")==OK)
	print("MUSIC_SALON_SAVED ",decor.get_child_count())
	for lib in libraries:lib.free()
	quit()



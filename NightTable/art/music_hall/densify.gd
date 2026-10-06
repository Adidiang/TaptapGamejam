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
	assert(not scene.has_node("SalonDetails"))
	var libraries=[]
	for path in ["res://art/music_hall/nine_assets/pack0.glb","res://art/music_hall/nine_assets/pack3_extra.glb","res://art/music_hall/nine_assets/pack0_extra.glb"]:
		var lib=load(path).instantiate()
		libraries.append(lib)
		for m in lib.find_children("*","MeshInstance3D",true,false):assets[str(m.name)]=m
	decor=Node3D.new()
	decor.name="SalonDetails"
	scene.add_child(decor)
	own(decor)
	decor.rotation.y=PI/2
	for side in [-1,1]:
		# Paired foreground seating clusters leave the side-door sightlines clear.
		for z in [.65,2.05]:
			prop("ForegroundVelvetChair","VelvetArmchair",Vector3(side*3.15,.12,z),Vector3(.95,1.25,1.0),180-side*12)
		prop("FrontGiltConsole","GiltConsole",Vector3(side*4.2,.12,1.1),Vector3(.7,.9,1.35),-side*90)
		prop("ConsoleFlowers","FlowerVase",Vector3(side*4.2,1.02,1.1),Vector3(.55,.8,.55))
		prop("ConsoleBooks","Books",Vector3(side*4.15,1.02,.65),Vector3(.36,.16,.3))
		# Stage wings are raised; anchor all props to the existing stage surface.
		prop("StagePedestal","Pedestal",Vector3(side*3.45,.83,-7.15),Vector3(.55,1.1,.55))
		prop("ComposerSculpture","ComposerBustA" if side<0 else "ComposerBustB",Vector3(side*3.45,1.93,-7.15),Vector3(.65,.78,.45))
		prop("StageConsole","GiltConsole",Vector3(side*3.7,.83,-9.25),Vector3(1.6,.85,.65))
		prop("StageFlowerVase","FlowerVase",Vector3(side*3.7,1.68,-9.25),Vector3(.65,.9,.65))
		prop("StageArmchair","VelvetArmchair",Vector3(side*3.55,.83,-5.5),Vector3(.83,1.25,.85),-side*18)
		prop("StageStandingCandles","FloorCandelabra",Vector3(side*4.55,.83,-6.7),Vector3(.58,2.2,.58))
		# Fill above the low side cabinets with architectural ornament.
		for z in [-6.8,-3.9]:
			prop("UpperBalconyCorbel","BalconyCorbel",Vector3(side*6.7,5.9,z),Vector3(.9,1.15,2.35),-side*90)
			prop("UpperBust","ComposerBustC",Vector3(side*6.5,7.05,z),Vector3(.75,1.1,.7),-side*90)
			for offset in [-.8,.8]:prop("UpperStoneUrn","StoneUrn",Vector3(side*6.55,7.05,z+offset),Vector3(.45,.55,.45))
		prop("SideFireplace","Fireplace",Vector3(side*7.0,.15,-5.5),Vector3(.6,3.2,1.9),-side*90)
		prop("MantelSculpture","ComposerBustC",Vector3(side*6.85,3.35,-5.5),Vector3(.55,.75,.5),-side*90)
		prop("CrystalPendant","CrystalChandelier",Vector3(side*4.4,5.8,-3.3),Vector3(1.45,3.9,1.45))
		spot("CandleWingGlow",Vector3(side*4.45,3.4,-5.8),Vector3(side*3.8,1.3,-7.4),"ffe0b8",2.2,5,48)
		spot("ForegroundSoftFill",Vector3(side*3.8,4.5,1),Vector3(side*3.3,.3,1.3),"c9d6df",1.4,7,42)
	prop("StageBackdropPainting","GrandPortrait",Vector3(0,3.15,-11.42),Vector3(3.5,3.7,.18))
	# All new objects are native editable nodes; keep existing camera transforms untouched.
	var packed=PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,"res://art/music_hall/music_hall.tscn")==OK)
	print("SALON_DETAILS_ADDED ",decor.get_child_count())
	for lib in libraries:lib.free()
	quit()



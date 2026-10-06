extends SceneTree
const LIB="res://art/tavern_library/meshes/"
var room: Node3D
var groups={}
var used={}
var rng=RandomNumberGenerator.new()
func _initialize(): call_deferred("build")
func group(label):
	var n=Node3D.new()
	n.name=label
	room.add_child(n)
	n.owner=room
	groups[label]=n
func backing(label,pos,dimensions):
	var node=MeshInstance3D.new()
	node.name=label
	node.mesh=BoxMesh.new()
	node.mesh.size=dimensions
	var mat=StandardMaterial3D.new()
	mat.albedo_color=Color("302d28")
	mat.roughness=1
	node.material_override=mat
	groups.Architecture.add_child(node)
	node.owner=room
	node.position=pos
func prop(kind,label,section,pos,dimensions,yaw=0.0):
	var mesh=load(LIB+kind+".res")
	var basis=Basis(Vector3.UP,deg_to_rad(yaw))
	var bounds: AABB=Transform3D(basis,Vector3.ZERO)*mesh.get_aabb()
	var scale_value=dimensions/Vector3(maxf(bounds.size.x,.00001),maxf(bounds.size.y,.00001),maxf(bounds.size.z,.00001))
	var node=MeshInstance3D.new()
	node.name=label
	node.mesh=mesh
	node.transform=Transform3D(Basis.from_scale(scale_value)*basis,pos-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*scale_value)
	groups[section].add_child(node)
	node.owner=room
	for i in mesh.get_surface_count():
		var mat=mesh.surface_get_material(i)
		if mat is StandardMaterial3D:
			mat=mat.duplicate()
			mat.metallic=0
			mat.metallic_specular=0
			mat.roughness=1
			mat.normal_enabled=false
			node.set_surface_override_material(i,mat)
	used[kind]=true
	return node
func bottles(label,pos,count,span):
	for i in count:
		var h=rng.randf_range(.23,.43)
		prop("bottle_%02d"%(i%6+1),label+"_%02d"%i,"BottlesAndVessels",pos+Vector3((float(i)/maxf(1,count-1)-.5)*span,0,rng.randf_range(-.08,.08)),Vector3(h*.46,h,h*.46),rng.randf_range(-25,25))
func light(label,pos,color,energy,reach,target=Vector3.INF,angle=50):
	var n: Light3D
	if target==Vector3.INF:
		n=OmniLight3D.new()
		n.omni_range=reach
		n.omni_attenuation=.85
	else:
		n=SpotLight3D.new()
		n.spot_range=reach
		n.spot_angle=angle
		n.spot_attenuation=.7
	n.name=label
	groups.Lighting.add_child(n)
	n.owner=room
	n.position=pos
	if target!=Vector3.INF: n.look_at(target)
	n.light_color=Color(color)
	n.light_energy=energy
	n.light_size=.25
	n.light_specular=0
	n.shadow_enabled=true
func build():
	rng.seed=4017
	room=Node3D.new()
	room.name="Cellar"
	root.add_child(room)
	for label in ["Architecture","RearStorage","BarrelStacks","SideStorage","BottlesAndVessels","SmallProps","Lighting","Cameras"]: group(label)
	backing("Ceiling",Vector3(0,4.7,-1.5),Vector3(9.5,.25,11))
	backing("RearMortar",Vector3(0,2.4,-7.15),Vector3(9.5,4.8,.12))
	for side in [-1,1]: backing("SideMortar",Vector3(side*4.85,2.4,-2),Vector3(.12,4.8,10))
	for x in [-3.0,0.0,3.0]:
		for z in [-5.5,-2.5,.5,3.5]: prop("floor_pavements_01","StoneFloor","Architecture",Vector3(x,0,z),Vector3(3,.001,3))
	for x in [-3.0,0.0,3.0]: prop("wall_rock_01","RearStone","Architecture",Vector3(x,0,-7),Vector3(3,5,.22),90)
	for side in [-1,1]:
		prop("wall_rock_01","SideStoneRear","Architecture",Vector3(side*4.6,0,-4.65),Vector3(.22,4.5,4.7))
		prop("wall_first_floor_door_arch_01","SideDoorWall","Architecture",Vector3(side*4.6,0,-.3),Vector3(.28,4.5,4),0 if side<0 else 180)
		prop("door_arch_01","DoorFrame","Architecture",Vector3(side*4.43,0,-.3),Vector3(.25,2.85,1.55),0 if side<0 else 180)
		for z in [-6.8,-2.35,1.8]: prop("pillar_floor_01","TimberPillar","Architecture",Vector3(side*4.35,0,z),Vector3(.38,4.4,.38))
	# Low ceiling and transverse ribs frame the storage wall without blocking the view.
	for z in [-6.8,-3.5,1.8]:
		prop("beam_01A","Crossbeam","Architecture",Vector3(0,4.4,z),Vector3(9,.26,.32),90)
	for side in [-1,1]:
		prop("beam_01B","UpperSideBeam","Architecture",Vector3(side*4.35,4.1,-2.5),Vector3(.28,.28,9))
	# Several different storage families rather than repeating a single shelf.
	for x in [-3.25,-1.62,0,1.62,3.25]:
		prop("wine_shelf_01","LowerWineRack","RearStorage",Vector3(x,0,-6.45),Vector3(1.42,1.45,.8),180)
		prop("wall_shelf_01","ShelfLedge","RearStorage",Vector3(x,1.48,-6.35),Vector3(1.5,.16,.72))
		bottles("RearBottles",Vector3(x,1.68,-6.12),7,1.25)
		for row in 3:
			for column in 4:
				var bottle=prop("bottle_%02d"%(column%6+1),"StoredWine","BottlesAndVessels",Vector3.ZERO,Vector3(.17,.48,.17))
				bottle.transform=Transform3D(Basis(Vector3.RIGHT,PI/2),Vector3(x-.48+column*.32,.22+row*.4,-6.25))*bottle.transform
	for x in [-3.3,3.3]:
		prop("bookshelf_02","TallBottleCabinet","RearStorage",Vector3(x,1.7,-6.65),Vector3(1.3,2,.58),180)
		for y in [2.05,2.6,3.15]: bottles("CabinetBottles",Vector3(x,y,-6.26),5,1)
		for y in [2.04,2.59,3.14]: prop("beam_01A","CabinetLedge","RearStorage",Vector3(x,y-.07,-6.3),Vector3(1.25,.07,.45),90)
	for x in [-1.6,1.6]:
		prop("shelf_02","UpperSupplies","RearStorage",Vector3(x,1.65,-6.6),Vector3(1.22,1.8,.6))
		for y in [1.85,2.4,2.95]: bottles("Supplies",Vector3(x,y,-6.19),4,.9)
	prop("shield_01","CellarCrest","RearStorage",Vector3(0,3,-6.75),Vector3(1.25,1.4,.2))
	for x in [-.85,.85]: prop("banner_02","HangingPennant","RearStorage",Vector3(x,3.35,-6.58),Vector3(.6,1,.12))
	# Horizontal casks with their original cradles, plus upright barrels and stock piles.
	for i in 3:
		prop("barrel_stand_medium_01","RearCask","BarrelStacks",Vector3(-1.35+i*1.1,0,-5.2),Vector3(1,1.25,1.1))
	prop("barrel_stand_small_01","StackedCask","BarrelStacks",Vector3(-.8,1.15,-5.25),Vector3(.9,.95,.9))
	for side in [-1,1]:
		prop("barrel_big_01","LargeVat","BarrelStacks",Vector3(side*3.6,0,-4.7),Vector3(1.25,1.65,1.25))
		prop("barrel_medium_01","SmallVat","BarrelStacks",Vector3(side*2.7,0,-5.2),Vector3(.8,1.05,.8))
		prop("shelf_01","SideStockShelf","SideStorage",Vector3(side*3.96,0,-3.1),Vector3(.82,2.8,1.6),-90 if side>0 else 90)
		prop("crate_closed_01","StockCrate","SmallProps",Vector3(side*3.4,0,-2),Vector3(.75,.65,.65),side*10)
		prop("crate_open_01","OpenCrate","SmallProps",Vector3(side*3.4,.65,-2),Vector3(.65,.45,.55),-side*8)
		bottles("CrateBottles",Vector3(side*3.4,1.04,-2),3,.45)
		prop("sackpile_01","Sacks","SmallProps",Vector3(side*2.7,0,-4.25),Vector3(.85,.65,.7),side*20)
		prop("wine_shelf_01","ForegroundWineRack","SideStorage",Vector3(side*3.85,0,1.4),Vector3(1.1,1.45,.85),180-side*20)
		bottles("ForegroundBottles",Vector3(side*3.85,1.5,1.4),5,.9)
		prop("barrel_stand_small_01","FrontCask","BarrelStacks",Vector3(side*2.85,0,1.65),Vector3(.95,.95,.9),-side*15)
		for j in 4:
			prop("pot_big_01" if j%2==0 else "jug_01","CeramicVessel","BottlesAndVessels",Vector3(side*(3.05+j*.35),0,-5.8+j*.27),Vector3(.3+j*.045,.42+j*.1,.3+j*.045),j*32)
		for z in [-4.5,.8]:
			prop("candlestick_wall_01","WallCandle","SmallProps",Vector3(side*4.2,2.4,z),Vector3(.36,.75,.38),-side*90)
			light("AmberWallPool",Vector3(side*3.95,2.85,z),"ffb47d",2.3,3.4)
	prop("bucket_01","Bucket","SmallProps",Vector3(-2.7,0,-1.8),Vector3(.4,.42,.4))
	prop("broom_01","Broom","SmallProps",Vector3(4.15,0,-1.7),Vector3(.35,1.45,.25))
	prop("chest_01","OldChest","SmallProps",Vector3(-3.1,0,-6),Vector3(.85,.6,.6))
	prop("table_rectangle_low_01","TastingTable","SideStorage",Vector3(2.7,0,-3.9),Vector3(1.1,.75,.65))
	prop("tray_01","TastingTray","SmallProps",Vector3(2.7,.76,-3.9),Vector3(.55,.05,.4))
	prop("gobelet_01","Goblet","SmallProps",Vector3(2.5,.81,-3.9),Vector3(.14,.23,.14))
	prop("tankard_01","Tankard","SmallProps",Vector3(2.85,.81,-3.9),Vector3(.2,.25,.18))
	for x in [-2.7,2.7]: prop("chandelier_01","HangingChandelier","SmallProps",Vector3(x,3.25,-1.4),Vector3(1.05,1.35,1.05))
	light("CoolRearFocus",Vector3(0,4,-3.5),"95c5ff",9,7,Vector3(0,2,-6.6),55)
	light("MintAisle",Vector3(.4,3.8,-1.5),"9bcac4",2.2,6,Vector3(0,0,-2),45)
	light("WarmLeftStock",Vector3(-2,3,-3),"ffc59b",6,5,Vector3(-2,1,-6),52)
	light("ForegroundAmber",Vector3(-2.8,1.1,1.6),"ffbe89",3.5,4)
	light("RightBottleRose",Vector3(2.8,1.8,.8),"f4abbd",2.2,3.5)
	light("SoftFrontFill",Vector3(0,2.8,5),"c6bed2",.85,12,Vector3(0,1,-4),65)
	var environment=WorldEnvironment.new()
	environment.name="PreviewEnvironment"
	room.add_child(environment)
	environment.owner=room
	var env=Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color("101b25")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("9daeb7")
	env.ambient_light_energy=.28
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled=true
	env.ssao_radius=.45
	env.ssao_intensity=1.4
	env.glow_enabled=true
	env.glow_intensity=.8
	env.glow_bloom=.1
	env.fog_enabled=true
	env.fog_light_color=Color("7eaaa7")
	env.fog_light_energy=.4
	env.fog_density=.007
	environment.environment=env
	for i in 3:
		var camera=Camera3D.new()
		camera.name=["CameraLeft","CameraRight","PreviewCamera"][i]
		groups.Cameras.add_child(camera)
		camera.owner=room
		camera.position=Vector3([-0.7,.7,0][i],2.8,6.2)
		camera.rotation_degrees.x=-7
		camera.fov=49
		camera.current=i==2
	var filter=load("res://art/exploration/room_paper_filter.tscn").instantiate()
	room.add_child(filter)
	filter.owner=room
	var packed=PackedScene.new()
	assert(packed.pack(room)==OK)
	assert(ResourceSaver.save(packed,"res://art/cellar/cellar.tscn")==OK)
	print("CELLAR_BUILT unique assets=",used.size()," meshes=",room.find_children("*","MeshInstance3D",true,false).size())
	quit()

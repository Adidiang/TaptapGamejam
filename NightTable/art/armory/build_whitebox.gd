extends SceneTree
var scene:Node3D
var stone:StandardMaterial3D
var timber:StandardMaterial3D
var steel:StandardMaterial3D
var red:StandardMaterial3D
var trim:StandardMaterial3D
func material(color:Color)->StandardMaterial3D:
	var m=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=.85
	return m
func group(label:String,parent:Node=null)->Node3D:
	var n=Node3D.new()
	n.name=label
	(parent if parent else scene).add_child(n)
	return n
func box(parent:Node,label:String,pos:Vector3,sz:Vector3,mat:Material)->MeshInstance3D:
	var n=MeshInstance3D.new()
	n.name=label
	var mesh=BoxMesh.new()
	mesh.size=sz
	n.mesh=mesh
	n.material_override=mat
	n.position=pos
	parent.add_child(n)
	return n
func cylinder(parent:Node,label:String,pos:Vector3,radius:float,height:float,mat:Material,top:float=-1)->MeshInstance3D:
	var n=MeshInstance3D.new()
	n.name=label
	var mesh=CylinderMesh.new()
	mesh.bottom_radius=radius
	mesh.top_radius=radius if top<0 else top
	mesh.height=height
	mesh.radial_segments=12
	n.mesh=mesh
	n.position=pos
	n.material_override=mat
	parent.add_child(n)
	return n
func sphere(parent:Node,label:String,pos:Vector3,sz:Vector3,mat:Material):
	var n=MeshInstance3D.new()
	n.name=label
	var mesh=SphereMesh.new()
	mesh.radius=.5
	mesh.height=1
	n.mesh=mesh
	n.position=pos
	n.scale=sz
	n.material_override=mat
	parent.add_child(n)
func blade(parent:Node,pos:Vector3,height:float):
	box(parent,"Blade",pos+Vector3(0,height*.37,0),Vector3(.13,height*.74,.055),steel)
	cylinder(parent,"Point",pos+Vector3(0,height*.84,0),.095,height*.26,steel,0)
	box(parent,"Guard",pos,Vector3(.42,.085,.11),trim)
	cylinder(parent,"Grip",pos-Vector3(0,.16,0),.048,.25,timber)
func shield(parent:Node,label:String,pos:Vector3,scale_value:float):
	var g=group(label,parent)
	g.position=pos
	g.scale=Vector3.ONE*scale_value
	var poly=PackedVector2Array([Vector2(-.35,.43),Vector2(.35,.43),Vector2(.39,-.1),Vector2(0,-.5),Vector2(-.39,-.1)])
	var surface=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1,poly.size()-1):
		for v in [poly[0],poly[i],poly[i+1]]:surface.add_vertex(Vector3(v.x,v.y,0))
	surface.generate_normals()
	var mesh=MeshInstance3D.new()
	mesh.mesh=surface.commit()
	var m=red.duplicate()
	m.cull_mode=BaseMaterial3D.CULL_DISABLED
	mesh.material_override=m
	g.add_child(mesh)
	box(g,"SuitDiamond",Vector3(0,.05,.035),Vector3(.19,.19,.035),trim).rotation.z=PI/4
	if label=="QueenCardCrest":
		g.get_node("SuitDiamond").hide()
		var points=PackedVector2Array()
		for i in 48:
			var t=TAU*float(i)/48.0
			points.append(Vector2(16*pow(sin(t),3),13*cos(t)-5*cos(2*t)-2*cos(3*t)-cos(4*t))*.012)
		var indices=Geometry2D.triangulate_polygon(points)
		var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in indices:st.add_vertex(Vector3(points[i].x,points[i].y+.03,.045))
		st.generate_normals()
		var emblem=MeshInstance3D.new();emblem.name="HeartEmblem";emblem.mesh=st.commit()
		var emblem_mat=trim.duplicate();emblem_mat.cull_mode=BaseMaterial3D.CULL_DISABLED
		emblem.material_override=emblem_mat;g.add_child(emblem)
func rack(parent:Node,label:String,pos:Vector3,width:float,count:int,spears:bool=false)->Node3D:
	var g=group(label,parent)
	g.position=pos
	g.set_meta("replace_with","Long weapon rack / swords and polearms")
	for x in [-width*.5,width*.5]:
		box(g,"RackUpright",Vector3(x,1.5,0),Vector3(.13,3,.18),timber)
		box(g,"Foot",Vector3(x,.13,.16),Vector3(.3,.20,.75),timber)
	for y in [.32,1.2,2.72]:box(g,"Crossbar",Vector3(0,y,0),Vector3(width,.14,.16),timber)
	for i in count:
		var x=-width*.42+float(i)*width*.84/float(count-1)
		var weapon=group("WeaponSlot_%02d"%i,g)
		weapon.position=Vector3(x,0,.18)
		weapon.rotation.z=deg_to_rad(-4+i%3*4)
		if spears:
			cylinder(weapon,"Shaft",Vector3(0,1.45,0),.032,2.5,timber)
			cylinder(weapon,"Spearhead",Vector3(0,2.91,0),.115,.40,steel,0)
		else:blade(weapon,Vector3(0,.86,0),1.40+float(i%3)*.22)
	return g
func armor(parent:Node,pos:Vector3,label:String):
	var g=group(label,parent)
	g.position=pos
	g.set_meta("replace_with","Royal armor on standing display")
	box(g,"Plinth",Vector3(0,.1,0),Vector3(.9,.2,.75),timber)
	for x in [-.16,.16]:box(g,"Greave",Vector3(x,.60,0),Vector3(.20,.82,.24),steel)
	cylinder(g,"Breastplate",Vector3(0,1.28,0),.33,.65,steel,.24)
	sphere(g,"Helmet",Vector3(0,1.96,0),Vector3(.40,.49,.39),steel)
	box(g,"Visor",Vector3(0,1.99,.195),Vector3(.3,.04,.04),timber)
	for x in [-.43,.43]:
		sphere(g,"Pauldron",Vector3(x,1.55,0),Vector3(.36,.30,.34),steel)
		box(g,"Gauntlet",Vector3(x,1.14,0),Vector3(.17,.60,.21),steel)
	box(g,"CardTabard",Vector3(0,1.17,.32),Vector3(.34,.60,.04),red)
func spot(label:String,pos:Vector3,target:Vector3,color:Color,energy:float):
	var n=SpotLight3D.new()
	n.name=label
	scene.add_child(n)
	n.position=pos
	n.basis=Basis.looking_at(target-pos)
	n.light_color=color
	n.light_energy=energy
	n.spot_range=16
	n.spot_angle=55
	n.light_size=.4
	n.shadow_enabled=true
func own(n:Node):
	for child in n.get_children():child.owner=scene;own(child)
func _initialize():
	scene=Node3D.new()
	scene.name="RoyalArmoryWhitebox"
	root.add_child(scene)
	stone=material(Color(.42,.48,.48))
	timber=material(Color(.21,.25,.25))
	steel=material(Color(.64,.67,.65))
	red=material(Color(.42,.16,.21))
	trim=material(Color(.60,.51,.36))
	var shell=group("Architecture")
	box(shell,"Floor_10x7",Vector3(0,-.10,0),Vector3(10,.20,7),stone)
	box(shell,"RearWall",Vector3(0,2.35,-3.55),Vector3(10,4.7,.15),stone)
	box(shell,"Ceiling",Vector3(0,4.79,0),Vector3(10,.18,7),stone)
	for z in [-2.9,-.45,2.5]:box(shell,"CeilingBeam",Vector3(0,4.62,z),Vector3(10,.16,.22),timber)
	for side in [-1,1]:
		var x=side*5.05
		box(shell,"SideWallRear",Vector3(x,2.35,-1.75),Vector3(.15,4.7,3.5),stone)
		box(shell,"SideWallFront",Vector3(x,2.35,2.45),Vector3(.15,4.7,2.1),stone)
		box(shell,"DoorLintel",Vector3(x,3.72,.70),Vector3(.15,1.96,1.4),stone)
		var doors=group("LeftDoor" if side<0 else "RightDoor")
		doors.set_meta("opening_size",Vector2(1.4,2.74))
		for z in [-.05,1.45]:box(doors,"Jamb",Vector3(side*4.92,1.4,z),Vector3(.26,2.8,.18),trim)
		box(doors,"FrameTop",Vector3(side*4.92,2.84,.7),Vector3(.26,.18,1.67),trim)
		box(doors,"Threshold",Vector3(side*4.92,.035,.7),Vector3(.45,.07,1.4),trim)
		var hinge=group("DoorHinge",doors)
		hinge.position=Vector3(side*5.12,0,-.01)
		box(hinge,"EditableDoorLeaf",Vector3(0,1.32,.69),Vector3(.08,2.64,1.36),timber)
		# Stored as separate hinge / leaf for the later integration owner.
		var mark=Marker3D.new();mark.name="DoorArrival";mark.position=Vector3(side*4.1,0,.7);doors.add_child(mark)
	for x in [-4.7,-1.55,1.55,4.7]:
		box(shell,"RearPilaster",Vector3(x,2.27,-3.34),Vector3(.25,4.54,.30),timber)
		box(shell,"Capital",Vector3(x,4.36,-3.28),Vector3(.45,.28,.42),trim)
	box(shell,"RearCornice",Vector3(0,4.58,-3.33),Vector3(10,.19,.38),trim)
	for x in [-4.88,4.88]:box(shell,"SideCornice",Vector3(x,4.58,0),Vector3(.26,.19,7),trim)
	var storage=group("WeaponStorage")
	rack(storage,"RearSwords",Vector3(-3.05,0,-2.97),2.32,7)
	rack(storage,"RearPolearms",Vector3(3.05,0,-2.97),2.32,6,true)
	var left=rack(storage,"LeftSideRack",Vector3(-4.48,0,-1.51),2.4,6,true)
	left.rotation.y=PI/2
	var right=group("RightShieldAndCrossbowCabinet",storage)
	right.position=Vector3(4.46,0,-1.5)
	right.rotation.y=-PI/2
	box(right,"CabinetBase",Vector3(0,.4,0),Vector3(2.45,.8,.55),timber)
	box(right,"Backboard",Vector3(0,1.95,-.12),Vector3(2.45,2.3,.13),timber)
	for x in [-.78,0,.78]:
		shield(right,"ShieldSlot",Vector3(x,2.35,.08),.8)
		box(right,"CrossbowStock",Vector3(x,1.27,.20),Vector3(.10,.64,.13),steel)
		box(right,"CrossbowLimbs",Vector3(x,1.42,.23),Vector3(.58,.09,.08),trim)
	armor(storage,Vector3(-1.8,0,-2.24),"ArmorLeft")
	armor(storage,Vector3(1.8,0,-2.24),"ArmorRight")
	# Hero silhouette: two oversized ceremonial polearms around a card shield.
	var hero=group("HeroCeremonialWeapons")
	box(hero,"RecessBacking",Vector3(0,2.6,-3.38),Vector3(2.6,3.45,.1),timber)
	for side in [-1,1]:
		var pole=group("GiantPolearm",hero)
		pole.position=Vector3(side*.35,.3,-2.96)
		pole.rotation.z=side*-.24
		cylinder(pole,"Handle",Vector3(0,1.72,0),.07,3.3,trim)
		blade(pole,Vector3(0,3.05,0),.70)
		var axe=box(pole,"AxeBlade",Vector3(side*.23,2.83,0),Vector3(.52,.39,.12),steel)
		axe.rotation.z=side*.25
	shield(hero,"QueenCardCrest",Vector3(0,2.97,-2.7),1.22)
	box(hero,"RelicChest",Vector3(0,.39,-2.75),Vector3(1.6,.78,.65),timber)
	# Low working table: blades, repair blocks and tools; no raised museum pedestal.
	var bench=group("CentralMaintenanceBench")
	bench.position=Vector3(-.40,0,-.78)
	bench.set_meta("replace_with","Low worn armorer workbench with repair tools")
	box(bench,"Top",Vector3(0,.84,0),Vector3(2.3,.16,.83),timber)
	for x in [-.94,.94]:box(bench,"Leg",Vector3(x,.39,0),Vector3(.17,.78,.6),timber)
	for i in 3:box(bench,"LaidBlade",Vector3(-.65+i*.6,.94,0),Vector3(.11,.04,.60),steel).rotation.y=.3
	box(bench,"AnvilBlock",Vector3(.73,1.06,-.11),Vector3(.39,.29,.28),steel)
	var props=group("ForegroundCratesAndRacks")
	for side in [-1,1]:
		for i in 2:
			var pos=Vector3(side*(3.5+i*.65),.32,2.55-i*.42)
			box(props,"WeaponCrate",pos,Vector3(1.05,.64,.67),timber)
			for dx in [-.38,.38]:box(props,"CrateBand",pos+Vector3(dx,0,0),Vector3(.08,.67,.7),trim)
		for i in 4:
			var spear=group("BundledSpear",props)
			spear.position=Vector3(side*(4.26+i*.10),0,2.53)
			spear.rotation.z=side*.15
			cylinder(spear,"Shaft",Vector3(0,1.05,0),.026,2.0,timber)
			cylinder(spear,"Tip",Vector3(0,2.18,0),.08,.27,steel,0)
		shield(props,"SpareShield",Vector3(side*3.54,.96,2.79),.85)
	# A few suspended card pennants add Wonderland scale without covering the racks.
	for x in [-3.05,3.05]:
		box(shell,"CardBanner",Vector3(x,3.98,-3.18),Vector3(.62,.95,.035),red)
		box(shell,"BannerDiamond",Vector3(x,3.98,-3.15),Vector3(.26,.26,.025),trim).rotation.z=PI/4
	var cams=group("Cameras")
	for pair in [["CameraLeft",-1.2],["MiddleCamera",0.0],["CameraRight",1.2]]:
		var camera=Camera3D.new();camera.name=pair[0];cams.add_child(camera)
		camera.position=Vector3(pair[1],3.1,9.5)
		camera.basis=Basis.looking_at(Vector3(0,1.90,-.7)-Vector3(0,3.1,9.5))
		camera.fov=48;camera.current=pair[0]=="MiddleCamera"
	var environment=WorldEnvironment.new()
	environment.name="PreviewEnvironment"
	environment.environment=Environment.new()
	var env=environment.environment
	env.background_mode=Environment.BG_COLOR;env.background_color=Color(.045,.065,.07)
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color(.76,.82,.86);env.ambient_light_energy=.48
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.ssao_enabled=true;env.ssao_radius=.4;env.ssao_intensity=1.25
	scene.add_child(environment)
	spot("CoolWindow",Vector3(-3.8,4.3,1),Vector3(0,.5,-1),Color(.68,.84,.89),4)
	spot("RoseRelic",Vector3(.4,4.2,-1.6),Vector3(0,2,-3),Color(1,.69,.74),3)
	spot("WarmDoor",Vector3(4.2,3.7,1.2),Vector3(1,.6,-1),Color(1,.83,.64),3.2)
	spot("SoftFront",Vector3(0,4,5),Vector3(0,1,-1),Color(.84,.84,1),1.6)
	var grade=load("res://art/exploration/room_paper_filter.tscn").instantiate();scene.add_child(grade)
	grade.get_node("DreamFilm").material=load("res://art/exploration/room_paper_filter.tres").duplicate()
	grade.get_node("DreamFilm").material.set_shader_parameter("softness",.10)
	grade.get_node("DreamFilm").material.set_shader_parameter("vignette_strength",.15)
	own(scene)
	var packed=PackedScene.new();assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,"res://art/armory/armory.tscn")==OK)
	print("ARMORY_WHITEBOX_SAVED")
	scene.queue_free();quit()

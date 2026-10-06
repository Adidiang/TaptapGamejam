extends SceneTree
var scene:Node3D
var decor:Node3D
var assets={}
var sizes={}
var gold:StandardMaterial3D
var rose:StandardMaterial3D
var mint:StandardMaterial3D
func mat(c:Color,metal:float=0.0)->StandardMaterial3D:
	var m=StandardMaterial3D.new();m.albedo_color=c;m.metallic=metal;m.roughness=.43;return m
func box(p:Node,pos:Vector3,sz:Vector3,m:Material):
	var n=MeshInstance3D.new();n.mesh=BoxMesh.new();n.mesh.size=sz;n.material_override=m;n.position=pos;p.add_child(n);return n
func add(id:String,pos:Vector3,h:float,yaw:float=0,p:Node=null)->Node3D:
	var n=assets[id].duplicate();(decor if p==null else p).add_child(n);n.name=id;n.position=pos;n.scale=Vector3.ONE*h/sizes[id][1];n.rotation.y=deg_to_rad(yaw);return n
func remove(path:String):
	var n=scene.get_node_or_null(path)
	if n:n.get_parent().remove_child(n);n.free()
func own(n:Node):
	for c in n.get_children():c.scene_file_path="";c.owner=scene;own(c)
func library(path:String,cat:String):
	var lib=load(path).instantiate()
	for e in JSON.parse_string(FileAccess.get_file_as_string(cat)):
		if lib.has_node(e.id):assets[e.id]=lib.get_node(e.id).duplicate();sizes[e.id]=e.size
	lib.free()
func lamp(pos:Vector3,c:Color,energy:float):
	var l=OmniLight3D.new();l.position=pos;l.light_color=c;l.light_energy=energy;l.omni_range=7;l.omni_attenuation=.65;l.light_size=.25;decor.add_child(l)
func _initialize():
	scene=load("res://art/armory/whitebox.tscn").instantiate();root.add_child(scene);scene.name="RoyalArmory"
	library("res://art/armory/weapons/weapons.glb","res://art/armory/weapons/catalog.json")
	for pair in [["courtyard","catalog"],["office","catalog"],["extra_courtyard","extra_catalog"],["extra_office","extra_catalog"]]:
		library("res://art/palace/fill_assets/"+pair[0]+".glb","res://art/palace/fill_assets/"+pair[1]+".json")
	decor=Node3D.new();decor.name="RoyalDecorAndImportedWeapons";scene.add_child(decor)
	gold=mat(Color(.65,.44,.19),.65);rose=mat(Color(.42,.18,.23));mint=mat(Color(.15,.29,.25))
	var paper=ShaderMaterial.new();paper.shader=load("res://art/armory/wallpaper.gdshader")
	var floor_mat=ShaderMaterial.new();floor_mat.shader=load("res://art/armory/checker_floor.gdshader")
	for n in scene.get_node("Architecture").get_children():
		if n is MeshInstance3D:
			var label=String(n.name)
			if label.contains("Wall") or label.contains("Lintel") or absf(n.position.x)>5.0:n.material_override=paper
			elif label.contains("Floor"):n.material_override=floor_mat
			elif label.contains("Ceiling"):n.material_override=rose
			else:n.material_override=gold
	for path in ["WeaponStorage","CentralMaintenanceBench","ForegroundCratesAndRacks"]:remove(path)
	for n in scene.get_node("HeroCeremonialWeapons").get_children():
		if n.name!="QueenCardCrest":n.get_parent().remove_child(n);n.free()
	# Rear velvet-lined weapon panels, with two tiers of real swords and shields.
	for side in [-1,1]:
		var x=side*3.08
		box(decor,Vector3(x,1.95,-3.34),Vector3(2.62,3.5,.16),mint)
		for dx in [-1.30,1.30]:box(decor,Vector3(x+dx,1.95,-3.2),Vector3(.06,3.55,.08),gold)
		for y in [.20,1.35,3.70]:box(decor,Vector3(x,y,-3.20),Vector3(2.65,.055,.08),gold)
		for i in 5:
			add("Sword0"+str(1+i%2),Vector3(x-1.02+i*.51,1.48,-3.0),1.75,-90)
		for i in 3:add("Shield%02d"%(3+i+(0 if side<0 else 7)),Vector3(x-.85+i*.85,.35,-2.98),.78,-90)
		add("C00",Vector3(side*1.84,0,-2.65),1.0,45)
		add("A05",Vector3(side*1.84,1.0,-2.65),.78)
		add("A07",Vector3(side*4.66,2.86,-3.06),.75)
		lamp(Vector3(side*4.3,3.1,-2.5),Color(1,.70,.62),.5)
		# Side-wall displays, ending before the door openings.
		var panel=Node3D.new();decor.add_child(panel);panel.position=Vector3(side*4.76,0,-1.7);panel.rotation.y=-side*PI/2
		box(panel,Vector3(0,1.95,0),Vector3(2.65,3.55,.15),mint)
		for xx in [-1.32,1.32]:box(panel,Vector3(xx,1.95,.12),Vector3(.055,3.6,.08),gold)
		for y in [.2,1.65,3.73]:box(panel,Vector3(0,y,.12),Vector3(2.7,.06,.08),gold)
		for i in 3:
			add("Shield%02d"%(13+i+(0 if side<0 else 6)),Vector3(-.88+i*.88,2.35,.25),.94,-90,panel)
			add("Sword0"+str(1+i%2),Vector3(-.88+i*.88,.25,.27),1.70,-90,panel)
		add("A23",Vector3(side*4.80,.0,.70),3.0,-side*90)
		# Arch wall module omitted to preserve door aperture
		# Front storage piles keep the central floor and both door approaches clear.
		add("O08",Vector3(side*3.60,0,2.40),.65,side*12)
		add("O09",Vector3(side*4.10,0,1.98),.48,-side*15)
		for i in 3:
			var sw=add("Sword0"+str(1+i%2),Vector3(side*(4.22+i*.13),.05,2.62),1.8,-90)
			sw.rotation.z=side*.15
		add("Shield%02d"%(21 if side<0 else 25),Vector3(side*3.50,.3,2.76),.94,-90)
		add("C14",Vector3(side*4.35,0,1.78),1.9)
		lamp(Vector3(side*4.25,2.0,1.8),Color(1,.71,.79),.7)
		add("C05",Vector3(side*4.84,2.6,2.58),1.35,-side*90)
	# Gilded central niche, drapery and exaggerated ceremonial sword silhouette.
	box(decor,Vector3(0,2.15,-3.32),Vector3(2.62,4.1,.12),rose)
	# Central frame uses light trim instead of the imported wall module
	# Drapery mesh is asymmetric; omit from hero niche
	for side in [-1,1]:
		var sword=add("Sword0"+str(1 if side<0 else 2),Vector3(side*.20,.60,-2.84),3.08,-90);sword.rotation.z=-side*.22
	add("O08",Vector3(0,0,-2.74),.75)
	add("A17",Vector3(0,.75,-2.75),.46)
	# Real carved furniture and small working objects replace the blockout bench.
	add("A03",Vector3(-.4,0,-.78),.90)
	for i in 3:
		var w=add("Dagger%02d"%(i+1),Vector3(-1.05+i*.5,.94,-.68),.55,-90);w.scale=Vector3.ONE*.55/maxf(sizes["Dagger%02d"%(i+1)][0],maxf(sizes["Dagger%02d"%(i+1)][1],sizes["Dagger%02d"%(i+1)][2]))
	add("O03",Vector3(.36,.91,-.84),.18)
	add("O12",Vector3(-1.04,.91,-1.03),.48)
	add("A10",Vector3(-.2,.91,-1.02),.17)
	add("A19",Vector3(.88,0,-1.04),1.12,-20)
	# Ceiling coffers and continuous skirting unify the reused furniture.
	for x in [-4.8,-2.4,0,2.4,4.8]:box(decor,Vector3(x,4.61,0),Vector3(.08,.14,7),gold)
	for z in [-3.3,-1.2,1.2,3.3]:box(decor,Vector3(0,4.60,z),Vector3(9.7,.14,.075),gold)
	for y in [.12,.85,3.85,4.46]:
		box(decor,Vector3(0,y,-3.37),Vector3(10,.065,.1),gold)
		for side in [-1,1]:
			for pair in [[-1.78,3.4],[2.50,1.90]]:box(decor,Vector3(side*4.94,y,pair[0]),Vector3(.1,.065,pair[1]),gold)
	add("C15",Vector3(0,3.25,.25),1.4)
	lamp(Vector3(0,3.45,.25),Color(1,.80,.72),2.2)
	var env=scene.get_node("PreviewEnvironment").environment.duplicate();scene.get_node("PreviewEnvironment").environment=env
	env.ambient_light_color=Color(.88,.81,1);env.ambient_light_energy=.48;env.glow_enabled=true;env.glow_intensity=.55
	env.fog_enabled=true;env.fog_light_color=Color(.62,.51,.64);env.fog_density=.003
	scene.get_node("CoolWindow").light_color=Color(.76,.89,1);scene.get_node("CoolWindow").light_energy=5
	scene.get_node("SoftFront").light_energy=3.0
	var film=scene.get_node("DreamGrade/DreamFilm");film.material=film.material.duplicate();film.material.set_shader_parameter("softness",.23);film.material.set_shader_parameter("vignette_strength",.18)
	for camera in scene.get_node("Cameras").get_children():camera.fov=43.0
	own(scene)
	var packed=PackedScene.new();assert(packed.pack(scene)==OK);assert(ResourceSaver.save(packed,"res://art/armory/armory.tscn")==OK)
	for a in assets.values():a.free()
	print("ARMORY_DRESSED_SAVED");scene.queue_free();quit()




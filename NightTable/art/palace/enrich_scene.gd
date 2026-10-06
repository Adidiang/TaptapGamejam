extends SceneTree
var room:Node3D
var group:Node3D
var sources={}
var sizes={}
var count=0
var wood:StandardMaterial3D
var gold:StandardMaterial3D
func add(id:String,h:float,d:float,y:float,height:float,angle:float=90.0)->Node3D:
	var obj:Node3D=sources[id].duplicate()
	obj.name="Detail_%03d_%s"%[count,id]
	count+=1
	group.add_child(obj)
	obj.position=Vector3(d,y,-h)
	obj.scale=Vector3.ONE*height/float(sizes[id][1])
	obj.rotation_degrees.y=angle
	obj.set_meta("source_asset",id)
	return obj
func block(label:String,pos:Vector3,sz:Vector3,mat:Material)->MeshInstance3D:
	var node=MeshInstance3D.new()
	node.name=label+str(group.get_child_count())
	var mesh=BoxMesh.new()
	mesh.size=sz
	node.mesh=mesh
	node.material_override=mat
	node.position=pos
	group.add_child(node)
	return node
func own(node:Node):
	for child in node.get_children():
		child.scene_file_path=""
		child.owner=room
		own(child)
func panel(h:float,d:float,side:bool):
	var p=Vector3(d,.76,-h)
	var size=Vector3(.10,1.3,.73) if not side else Vector3(.73,1.3,.10)
	block("Wainscot",p,size,wood)
	for offset in [-.30,.30]:
		var q=p+Vector3(.062,0,offset) if not side else p+Vector3(offset,0,.062 if h>0 else -.062)
		block("RaisedPanelEdge",q,Vector3(.035,1.12,.035),gold)
	for y in [.22,1.30]:
		var q=Vector3(d+.062,y,-h) if not side else Vector3(d,y,-h+(.062 if h>0 else -.062))
		block("RaisedPanelRail",q,Vector3(.035,.035,.63) if not side else Vector3(.63,.035,.035),gold)
func _initialize():
	room=load("res://art/palace/palace.tscn").instantiate()
	root.add_child(room)
	if room.has_node("Enrichment"):
		var old=room.get_node("Enrichment")
		room.remove_child(old)
		old.free()
	group=Node3D.new()
	group.name="Enrichment"
	room.add_child(group)
	for file in ["courtyard","office","extra_courtyard","extra_office"]:
		var lib=load("res://art/palace/fill_assets/"+file+".glb").instantiate()
		for child in lib.get_children():sources[String(child.name)]=child.duplicate()
		lib.free()
	for file in ["catalog","extra_catalog"]:
		for item in JSON.parse_string(FileAccess.get_file_as_string("res://art/palace/fill_assets/"+file+".json")):sizes[item.id]=item.size
	var wallpaper=ShaderMaterial.new()
	wallpaper.shader=load("res://art/palace/wallpaper.gdshader")
	var floor_mat=ShaderMaterial.new()
	floor_mat.shader=load("res://art/palace/checker_floor.gdshader")
	for key in ["立方体_004","立方体_003","立方体_002"]:room.get_node("Layout/"+key).material_override=wallpaper
	room.get_node("Layout/立方体").material_override=floor_mat
	wood=StandardMaterial3D.new()
	wood.albedo_color=Color(.11,.056,.039)
	wood.roughness=.65
	gold=StandardMaterial3D.new()
	gold.albedo_color=Color(.44,.29,.13)
	gold.metallic=.65
	gold.roughness=.42
	room.get_node("Layout/立方体_001").material_override=wood
	# Remove the previous sparse top-row objects: a continuous balustrade replaces them.
	for node in room.get_node("Dressing").get_children():
		if node.position.y>5.0 or (node.position.y>2.70 and node.position.y<2.80 and node.position.z<2.5 and node.position.z>1.0):
			node.get_parent().remove_child(node)
			node.free()
	# Full wall coverage: wallpaper above, framed dark wood below.
	for i in 12:panel(-4.15+i*.75,-3.33,false)
	for h in [-4.39,4.39]:
		for i in 6:panel(h,-3.0+i*.72,true)
		panel(h,2.85,true)
		for y in [.13,1.48,5.34,5.68]:
			# Low rails stop at each door; upper cornices run over the openings.
			if y<2:
				block("SideDado",Vector3(-1.13,y,-h),Vector3(4.40,.075,.16),gold)
				block("FrontDado",Vector3(2.8,y,-h),Vector3(.8,.075,.16),gold)
			else:block("SideCornice",Vector3(-.2,y,-h),Vector3(6.5,.1,.22),gold)
	for y in [.13,1.48,5.34,5.68]:block("RearCornice",Vector3(-3.25,y,0),Vector3(.20,.10,8.9),gold)
	# Gold screens form an ornate frieze beneath the ceiling.
	for i in 10:
		var obj=add("B20",-4.0+i*.86,-3.22,5.38,.28,90)
		obj.scale.x*=1.8
	for h in [-4.30,4.30]:
		for i in 7:add("B20",h,-2.9+i*.82,5.38,.28,0 if h<0 else 180)
	# Repeated carved arches break up the wallpaper like the concept's architectural frames.
	for h in [-4.03,-2.4,2.1,3.92]:
		add("A01",h,-3.18,3.43,1.80,90)
	# Large drapes at both edges and around the side doorways (door leaves remain independent).
	add("A23",-4.20,-1.70,1.65,3.6,180)
	add("A23",4.20,-1.40,1.70,3.55,0)
	for h in [-4.25,4.25]:
		var curtain=add("A23",h,1.75,.14,3.9,180 if h<0 else 0)
		# Wider opening around the existing 1.23 m doors.
		curtain.scale.x*=1.25
	# New furniture group at left, packed with different objects.
	add("B04",-4.01,-2.45,.11,2.2,90)
	add("A03",-3.34,-.70,.11,.80,135)
	add("A19",-2.8,-.83,.11,1.05,125)
	add("A14",-3.42,-.65,.92,.085,45)
	add("A15",-3.12,-.86,.92,.29)
	add("A11",-3.07,-.49,.92,.23)
	add("A17",-3.77,-.79,.92,.58)
	add("A22",-3.53,-.41,.92,.035,45)
	# Corner flowers and pedestal ornaments fill the vertical gaps.
	for entry in [[-4.0,-2.75,3.32,.65],[-2.55,-2.7,3.3,.7],[-.25,-2.65,1.22,.72],[3.97,.15,1.05,.72],[-3.65,2.89,1.22,.9],[3.40,3.32,.9,.66]]:
		add("A05",entry[0],entry[1],entry[2],entry[3],70)
	add("A18",-3.96,.25,1.22,.78)
	add("A17",-3.95,-2.1,2.40,.65)
	add("A05",2.95,-2.40,4.37,.7)
	# Wall sconces and extra small art fill the remaining gaps.
	for h in [-3.96,-2.50,-.25,1.4,3.85]:add("A07",h,-3.02,3.25,.64,90)
	for h in [-4.23,4.23]:
		for d in [-2.8,-.2,2.78]:add("A07",h,d,2.95,.62,180 if h<0 else 0)
	add("A08",-2.26,-3.09,3.76,.82,90)
	add("C09",-3.95,-3.09,4.65,.49,90)
	add("A16",-4.27,.40,2.3,.50,180)
	# Tall foreground framing and layered shelves.
	add("A06",-4.0,2.87,.11,2.35,90)
	add("A21",-3.28,2.96,1.22,.53,45)
	add("A09",-2.80,3.0,1.22,.56,0)
	add("B06",-3.13,3.0,1.22,.1,30)
	add("B09",-3.1,3.28,1.22,.16)
	add("B12",-2.89,3.20,1.22,.27)
	add("A10",-2.74,2.84,.11,.34,30)
	add("A13",-2.74,2.84,.45,.14,30)
	add("B01",3.62,2.80,.11,.62,90)
	add("B08",3.48,2.8,.74,.18)
	add("B10",3.82,2.8,.74,.14)
	add("B05",3.72,2.7,.74,.32)
	# Fill the original shelves and side tables with more varied shapes.
	for i in range(8):
		var h=-4.05+i*.46
		add(["A12","A13","B09","B14"][i%4],h,-2.77,5.0,.20,25+i*27)
		block("CurioShelf",Vector3(-2.79,4.97,-h),Vector3(.38,.06,.43),wood)
	for i in range(5):
		add(["B05","B07","B08","B12","B13"][i],-4.12,-1.75+i*.43,2.24,.24,80)
	for i in range(4):
		add(["B09","A12","B14","A13"][i],-2.22,-2.59,.6+i*.43,.15,45)
	# Additional flowers at the near edges replace large featureless wall patches.
	add("A17",-4.05,2.92,1.2,.9)
	add("A18",4.00,2.94,.78,.95)
	add("A05",-4.05,-1.9,.1,1.12)
	# Keep illumination readable against the newly dark materials.
	room.get_node("PreviewEnvironment").environment.ambient_light_energy=.46
	own(room)
	var packed=PackedScene.new()
	assert(packed.pack(room)==OK)
	assert(ResourceSaver.save(packed,"res://art/palace/palace.tscn")==OK)
	print("ENRICHMENT_SAVED_ASSET_GROUPS ",count)
	for item in sources.values():item.free()
	room.queue_free()
	quit()

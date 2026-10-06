extends SceneTree
var room:Node3D
var dressing:Node3D
var sources={}
var sizes={}
var count=0
func ledge(h:float,d:float,y:float,width:float,depth:float):
	var obj=MeshInstance3D.new()
	obj.name="DisplayLedge_%s"%dressing.get_child_count()
	var box=BoxMesh.new()
	box.size=Vector3(depth,.09,width)
	obj.mesh=box
	var mat=StandardMaterial3D.new()
	mat.albedo_color=Color(.28,.16,.115)
	mat.roughness=.65
	obj.material_override=mat
	obj.position=Vector3(d,y-.045,-h)
	dressing.add_child(obj)
func add(id:String,h:float,d:float,y:float,height:float,angle:float=90.0)->Node3D:
	var obj:Node3D=sources[id].duplicate()
	obj.name="Fill_%03d_%s"%[count,id]
	count+=1
	dressing.add_child(obj)
	obj.position=Vector3(d,y,-h)
	obj.scale=Vector3.ONE*height/float(sizes[id][1])
	obj.rotation_degrees.y=angle
	obj.set_meta("source_asset",id)
	return obj
func own(node:Node):
	for child in node.get_children():
		child.scene_file_path=""
		child.owner=room
		own(child)
func tabletop(h:float,d:float,y:float):
	add("C19",h-.22,d,y,.25,65)
	add("O12",h+.22,d,y,.48)
	add("O13",h+.02,d+.13,y,.3,30)
	add("O14",h-.13,d+.22,y,.09,110)
func _initialize():
	room=load("res://art/palace/palace.tscn").instantiate()
	root.add_child(room)
	if room.has_node("Dressing"):
		var old=room.get_node("Dressing")
		room.remove_child(old)
		old.free()
	dressing=Node3D.new()
	dressing.name="Dressing"
	room.add_child(dressing)
	for file in ["courtyard","office"]:
		var lib=load("res://art/palace/fill_assets/"+file+".glb").instantiate()
		for child in lib.get_children():sources[String(child.name)]=child.duplicate()
		lib.free()
	for item in JSON.parse_string(FileAccess.get_file_as_string("res://art/palace/fill_assets/catalog.json")): sizes[item.id]=item.size
	# Dense rear-wall salon around the retained heart crest and wardrobe.
	add("C03",-2.0,-2.86,.1,2.5,90)
	add("C00",-.55,-2.75,.1,1.0,135)
	tabletop(-.55,-2.70,1.1)
	add("O00",-4.02,-1.85,.1,1.05,90)
	tabletop(-4.02,-1.85,1.15)
	add("C14",-1.23,-2.6,.1,1.8)
	add("C13",.1,-2.63,.1,1.5)
	# Framed gallery rising above the original furniture.
	add("C05",-3.25,-3.32,3.48,1.15,90)
	add("C07",-1.55,-3.30,4.32,.85,45)
	add("C09",.0,-3.27,4.37,.7,90)
	add("C07",1.6,-3.26,4.32,.85,45)
	add("C05",3.15,-3.28,4.32,.85,90)
	add("C09",-2.0,-3.22,3.04,.56,90)
	add("C05",-4.08,-3.25,3.12,.78,90)
	add("O06",-.14,-2.70,1.40,.75,145)
	# Left wall: furniture and paintings stop before the doorway at depth 1.13..2.36.
	add("C00",-4.02,-.42,.1,1.1,45)
	tabletop(-4.0,-.42,1.2)
	add("C17",-3.72,-1.28,.1,.93,45)
	add("C07",-4.35,-1.22,2.75,1.3,135)
	add("C05",-4.35,.22,3.2,.86,180)
	add("C14",-4.03,.54,.1,1.85)
	ledge(-3.55,-2.72,3.3,1.8,.55)
	add("C22",-3.95,-2.6,3.3,.42)
	add("O15",-3.95,-2.6,3.66,.55)
	add("O01",-2.83,-2.65,3.3,.55)
	# Right bedside details and high wall art, clear of the second doorway.
	add("C01",3.97,.15,.1,.95,45)
	add("O07",3.97,.15,1.05,.62)
	add("O14",3.82,.36,1.05,.1)
	add("C14",4.04,-1.03,.1,1.8)
	add("C05",4.33,-1.42,3.25,1.05,0)
	add("C09",4.34,.18,3.47,.68,0)
	# Foreground clusters echo the concept, with the center floor kept open.
	add("C00",-3.25,2.88,.1,1.12,135)
	tabletop(-3.25,2.88,1.22)
	add("C14",-4.0,2.85,.1,2.45)
	add("O01",-2.67,2.8,.1,.95)
	add("O15",-2.67,2.8,.97,.72)
	add("O08",-2.38,3.05,.1,.48,55)
	add("C19",-2.36,3.05,.58,.28)
	add("C16",-3.73,2.93,.1,1.12,120)
	add("O09",-2.72,3.20,.1,.24)
	# Existing vanity top, front right.
	for h in [.7,1.35,2.9,3.5]:
		add("O12",h,3.63,.90,.32+(h/20.0),45)
		add("O13",h+.13,3.76,.90,.22,20)
	add("O09",1.65,3.68,.90,.16,70)
	add("O11",.9,3.8,.90,.22,45)
	add("O17",1.12,3.9,.90,.14)
	add("O01",3.6,2.85,.1,.8)
	add("O15",3.6,2.85,.85,.65)
	# More shelf-like stacked curios at the back and layered floor accents at edges.
	for i in range(3):
		add("C19",-2.0,-2.1,.1+i*.27,.27,80+i*15)
	# Stock each level of the imported cabinet with varied books and curios.
	for level in range(4):
		var y=.59+level*.43
		add("O04",-2.25,-2.62,y,.20,90+level*20)
		add("C19",-1.97,-2.62,y,.23,80+level*12)
		add("O13" if level%2==0 else "O19",-1.65,-2.62,y,.27,60)
	# Secondary wall shelves and small framed paintings enrich the left wall.
	ledge(-4.2,-.60,2.24,.4,2.85)
	for i in range(6):
		var d=-1.8+i*.43
		add("C19" if i%2==0 else "O01",-4.18,d,2.24,.25+(i%3)*.07,30+i*23)
	add("C09",-4.34,-2.48,3.65,.65,180)
	add("C05",-4.34,-.72,4.18,.69,180)
	add("C07",-4.34,.33,4.23,.8,135)
	# Layered boxes and ceramics at the room edges.
	add("O08",-3.10,.40,.1,.4,45)
	add("O09",-3.10,.40,.5,.21,65)
	add("C19",-3.55,.40,.1,.31,10)
	add("C22",-3.55,.40,.41,.27)
	add("O04",3.93,.18,.26,.22,45)
	add("O18",3.93,.18,.48,.1,35)
	add("O01",-3.55,2.88,1.22,.45)
	add("O16",-2.92,2.85,1.22,.25)
	add("O18",-3.15,3.04,1.22,.12,80)
	add("O04",-.15,-2.6,1.1,.19,30)
	add("O12",-.7,-2.55,1.35,.36)
	for i in range(3):
		add("O18",-.80+i*.22,-2.51,1.15,.12,i*30)
	add("C18",-.35,-2.48,1.12,.20)
	add("O11",-4.02,-.1,1.2,.3,45)
	add("O17",-3.85,-.15,1.2,.19)
	add("O08",-3.25,-1.95,.1,.46,20)
	add("O04",-3.25,-1.95,.56,.22)
	ledge(-1.8,-2.82,2.76,1.45,.55)
	add("O01",-1.35,-2.85,2.76,.45)
	add("O12",-2.22,-2.83,2.76,.62)
	# Decorative upper row follows the concept's filled crown line.
	ledge(0,-3.12,5.12,8.7,.48)
	for i in range(11):
		var h=-4.0+i*.78
		add("C13",h,-3.12,5.12,.66,90)
	for h in [-4.0,-2.8,-1.6,.0,1.3,2.5,3.8]:
		add("C21",h,-3.04,5.12,.26)
	own(room)
	var packed=PackedScene.new()
	assert(packed.pack(room)==OK)
	assert(ResourceSaver.save(packed,"res://art/palace/palace.tscn")==OK)
	print("DRESSING_SAVED_COUNT ",count)
	for source in sources.values():source.free()
	room.queue_free()
	quit()

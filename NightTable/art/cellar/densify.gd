extends "res://art/cellar/build.gd"
func _initialize(): call_deferred("revise")
func revise():
	rng.seed=924
	room=load("res://art/cellar/cellar.tscn").instantiate()
	root.add_child(room)
	assert(not room.has_meta("dense_revision"),"Already applied; edit the native scene directly.")
	for node in room.get_children(): groups[str(node.name)]=node
	# Bring the entire rear vignette forward, including bottles and floor stock.
	for section in ["RearStorage","BarrelStacks","BottlesAndVessels","SmallProps","SideStorage"]:
		for node in groups[section].get_children():
			if node is MeshInstance3D:
				var bounds: AABB=node.transform*node.get_aabb()
				if bounds.get_center().z < -3.7: node.position.z+=1.05
	# Low cabinets occupy the midground, with more closed storage behind the bottles.
	for side in [-1,1]:
		prop("drawer_01","Sideboard","RearStorage",Vector3(side*2.45,0,-3.3),Vector3(1.3,1.12,.7),90)
		bottles("SideboardBottles",Vector3(side*2.45,1.14,-3.3),6,1.05)
		prop("bookshelf_01","AdditionalCupboard","RearStorage",Vector3(side*3.85,0,-4.5),Vector3(1.05,2.3,.6))
		for y in [.45,1.05,1.65]: bottles("CupboardStock",Vector3(side*3.85,y,-4.1),4,.8)
		prop("chest_01","MidgroundChest","SmallProps",Vector3(side*2.65,0,-1.25),Vector3(.9,.55,.6),side*18)
		prop("grain_sack_01","GrainBag","SmallProps",Vector3(side*2.15,0,-2.35),Vector3(.45,.64,.44),side*25)
		prop("pot_big_02","FloorUrn","BottlesAndVessels",Vector3(side*2.8,0,-.65),Vector3(.42,.66,.42))
		prop("crate_open_01","FrontHamper","SmallProps",Vector3(side*2.05,0,2.25),Vector3(.9,.5,.72),-side*15)
		bottles("HamperWine",Vector3(side*2.05,.38,2.25),4,.65)
		prop("sackpile_02","FrontSackPile","SmallProps",Vector3(side*3.15,0,2.75),Vector3(1,.62,.75),side*30)
		prop("pot_big_01","FrontAmphora","BottlesAndVessels",Vector3(side*1.55,0,2.8),Vector3(.48,.72,.48))
		prop("jug_01","FrontJug","BottlesAndVessels",Vector3(side*1.18,0,3.05),Vector3(.28,.38,.3))
	prop("rug_green_01","WornCentralRug","SmallProps",Vector3(0,.015,-.5),Vector3(3.2,.018,3.5))
	prop("bucket_01","WorkBucket","SmallProps",Vector3(-1.9,0,.15),Vector3(.4,.42,.4))
	prop("bottle_04","AbandonedBottle","BottlesAndVessels",Vector3(-1.6,0,.1),Vector3(.16,.36,.16))
	prop("bench_01","FrontWorkBench","SmallProps",Vector3(.15,0,3.6),Vector3(1.3,.48,.4),-8)
	prop("bookpile_01","LedgerPile","SmallProps",Vector3(.2,.49,3.6),Vector3(.45,.19,.3),-8)
	var textures={}
	var count=0
	for mesh in room.find_children("*","MeshInstance3D",true,false):
		for i in mesh.mesh.get_surface_count():
			var mat=mesh.get_active_material(i)
			if mat is StandardMaterial3D and mat.albedo_texture:
				var source=mat.albedo_texture.resource_path
				var path="res://art/cellar/textures/"+source.get_file()
				if ResourceLoader.exists(path):
					if not textures.has(path): textures[path]=load(path)
					mat=mat.duplicate()
					mat.albedo_texture=textures[path]
					mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
					mat.normal_enabled=false
					mat.roughness=1
					mat.metallic_specular=0
					mesh.set_surface_override_material(i,mat)
					count+=1
	room.set_meta("dense_revision",true)
	var packed=PackedScene.new()
	assert(packed.pack(room)==OK)
	assert(ResourceSaver.save(packed,"res://art/cellar/cellar.tscn")==OK)
	for path in textures: print("CELLAR_TEXTURE ",path," ",textures[path].get_size())
	print("DENSIFY_OK materials=",count)
	quit()

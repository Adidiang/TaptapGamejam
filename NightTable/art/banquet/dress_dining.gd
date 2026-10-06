extends SceneTree
var room: Node3D
var library: Node3D
var dressing: Node3D
const TURN = Basis(Vector3.UP,PI/2)
func _initialize(): call_deferred("build")
func own(node):
	node.owner=room
	node.scene_file_path=""
	for child in node.get_children(): own(child)
func place(asset: String,label: String,pos: Vector3,dimensions: Vector3,yaw: float=0):
	var source = library.get_node(asset) as MeshInstance3D
	assert(source!=null,asset)
	var node=source.duplicate() as MeshInstance3D
	node.name=label
	dressing.add_child(node)
	node.transform=Transform3D.IDENTITY
	var size=source.get_aabb().size
	node.scale=dimensions/size
	node.rotation.y=deg_to_rad(yaw)+PI/2
	node.position=TURN*pos
	for i in node.mesh.get_surface_count():
		var old=node.get_active_material(i)
		if old is StandardMaterial3D:
			var mat=old.duplicate()
			mat.roughness=1.0
			mat.metallic_specular=0.0
			node.set_surface_override_material(i,mat)
	own(node)
	return node
func glow(label,pos):
	var lamp=OmniLight3D.new()
	lamp.name=label
	dressing.add_child(lamp)
	lamp.position=TURN*pos
	lamp.light_color=Color("ffd2a1")
	lamp.light_energy=0.5
	lamp.omni_range=3.5
	lamp.light_specular=0
	own(lamp)
func build():
	room=load("res://art/banquet/banquet.tscn").instantiate()
	root.add_child(room)
	assert(not room.has_node("DiningDecor"),"Decoration already exists; edit the existing nodes instead of rebuilding")
	library=load("res://art/banquet/dining_assets/selected.glb").instantiate()
	dressing=Node3D.new()
	dressing.name="DiningDecor"
	room.add_child(dressing)
	dressing.owner=room
	place("Wainscot","BackWallPanels",Vector3(0,0.1,-11.65),Vector3(8.8,1.45,0.22))
	place("Cornice","BackCarvedCornice",Vector3(0,4.65,-11.55),Vector3(8.8,1.1,0.22))
	for side in [-1,1]:
		var suffix="Left" if side<0 else "Right"
		var yaw=-side*90.0
		place("Curtain","VelvetCurtain_"+suffix,Vector3(side*3.25,0.2,-11.2),Vector3(2.05,5.1,0.4))
		place("TallCabinet","DisplayCabinet_"+suffix,Vector3(side*3.5,0.1,-9.8),Vector3(1.35,2.8,0.72))
		place("Sideboard","Sideboard_"+suffix,Vector3(side*3.98,0.1,-7.3),Vector3(2.35,1.3,0.7),yaw)
		place("StandingCandelabra","FloorCandelabra_"+suffix,Vector3(side*2.85,0.1,-7.8),Vector3(0.5,2.2,0.5))
		for z in [-8.5,-4.6]:
			place("Wainscot","WallPanels_%s_%s"%[suffix,str(z)],Vector3(side*4.34,0.1,z),Vector3(3.7,1.4,0.18),yaw)
			place("Cornice","UpperCarving_%s_%s"%[suffix,str(z)],Vector3(side*4.28,4.8,z),Vector3(3.7,0.95,0.22),yaw)
		for z in [-7.1,-2.35]:
			place("WallSconce","WallLamp_%s_%s"%[suffix,str(z)],Vector3(side*4.25,3.0,z),Vector3(0.7,0.73,0.34),yaw)
			glow("WarmPool_%s_%s"%[suffix,str(z)],Vector3(side*3.95,3.45,z))
		place("CarvedMedallion","WallMedallion_"+suffix,Vector3(side*4.28,2.5,-4.8),Vector3(1.05,1.2,0.22),yaw)
		place("Pedestal","DoorPedestal_"+suffix,Vector3(side*4.0,0.1,1.85),Vector3(0.48,1.5,0.48),yaw)
	place("Chandelier","ForegroundChandelier",Vector3(0,4.55,0.15),Vector3(1.0,1.3,1.0))
	# Save editable native nodes; original composition/camera/light nodes are untouched.
	var packed=PackedScene.new()
	assert(packed.pack(room)==OK)
	assert(ResourceSaver.save(packed,"res://art/banquet/banquet.tscn")==OK)
	library.free()
	print("DINING_DECOR_SAVED ",dressing.get_child_count())
	quit()

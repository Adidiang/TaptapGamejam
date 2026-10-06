extends SceneTree
var room:Node3D
func own(node:Node):
	for child in node.get_children():
		child.scene_file_path=""
		child.owner=room
		own(child)
func _initialize():call_deferred("run")
func run():
	room=load("res://art/palace/palace.tscn").instantiate()
	root.add_child(room)
	var layout=room.get_node("Layout")
	var old=layout.get_node_or_null("tripo_node_c93fc015-e3fe-4871-9491-cdf6ac717d70")
	if old==null:old=layout.get_node("EmpressBed")
	layout.remove_child(old)
	var bed=load("res://art/palace/empress_bed.glb").instantiate()
	bed.name="EmpressBed"
	layout.add_child(bed)
	var bounds=AABB()
	var first=true
	for mesh in bed.find_children("*","MeshInstance3D",true,false):
		var b=bed.global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
		bounds=b if first else bounds.merge(b)
		first=false
	# The replacement asset's foot faces +X; the original bed's foot faces +Z.
	var orientation=Basis(Vector3.UP,atan2(.5025301,1.3494745)-PI/2)
	var scale_factor=4.25
	bed.basis=orientation.scaled(Vector3.ONE*scale_factor)
	var bottom_center=Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
	bed.position=Vector3(-1.0329905,.100552395,-2.1043327)-bed.basis*bottom_center
	bed.set_meta("source_file","女皇寝室床.glb")
	old.free()
	own(room)
	var packed=PackedScene.new()
	assert(packed.pack(room)==OK)
	assert(ResourceSaver.save(packed,"res://art/palace/palace.tscn")==OK)
	print("EMPRESS_BED_REPLACED scale=",scale_factor," position=",bed.position)
	room.queue_free()
	await process_frame
	quit()

extends SceneTree
## One-time migration of the original studies to editable gameplay templates.
var owner_root: Node3D

func _initialize() -> void:
	call_deferred("prepare")

func mesh_part(parent: Node3D, title: String, key: String, pos: Vector3, size: Vector3 = Vector3.ONE) -> Node3D:
	var pivot = Node3D.new()
	pivot.name = title
	parent.add_child(pivot)
	pivot.position = pos
	pivot.scale = size
	var model = MeshInstance3D.new()
	model.name = "Model"
	model.mesh = load("res://art/tavern_library/meshes/"+key+".res")
	var bounds = model.mesh.get_aabb()
	model.position = -Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
	pivot.add_child(model)
	return pivot

func own(node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_root
		own(child)

func save(node: Node3D, path: String) -> void:
	owner_root = node
	own(node)
	var packed = PackedScene.new()
	assert(packed.pack(node)==OK)
	assert(ResourceSaver.save(packed,path)==OK)
	node.free()

func prepare() -> void:
	if FileAccess.get_file_as_string("res://art/room_studies/battle_room.tscn").contains("room_art_template.gd"):
		push_error("Room templates have already been migrated. Edit them directly in Godot.")
		quit(1)
		return
	var doorway = Node3D.new()
	doorway.name = "Doorway"
	var opening = Node3D.new()
	opening.name = "Opening"
	doorway.add_child(opening)
	for z in [-1.15,1.15]:
		mesh_part(opening,"JambBack" if z<0 else "JambFront","pillar_floor_01",Vector3(0,0,z),Vector3(0.65,0.86,0.65))
	var hinge = Node3D.new()
	hinge.name = "Hinge"
	hinge.position.z = -1.05
	opening.add_child(hinge)
	mesh_part(hinge,"DoorLeaf","door_arch_01",Vector3(0,0,1.05),Vector3(1,1,1.25))
	var wall = mesh_part(doorway,"SealedWall","wall_first_floor_01",Vector3(0,0,0.7),Vector3(1,1,1.05))
	wall.visible = false
	save(doorway,"res://art/room_studies/doorway.tscn")
	for filename in ["battle_room","event_room","shop_room"]:
		var path = "res://art/room_studies/"+filename+".tscn"
		var scene = load(path).instantiate()
		for section in scene.get_children():
			var counts = {}
			for child in section.get_children():
				var key = String(child.name)
				if child is Node3D and child.has_node("Model"):
					key = child.get_node("Model").mesh.resource_path.get_file().get_basename()
					if key=="door_arch_01":
						child.name = "LeftDoorPreview" if child.position.x<0 else "RightDoorPreview"
						continue
				elif child is OmniLight3D: key = "LocalLight"
				else: continue
				counts[key] = counts.get(key,0)+1
				child.name = key+"_%02d" % counts[key]
		# Local fill belongs to room art, not the preview-only global rig.
		for child in scene.get_node("PreviewRig").get_children():
			if child is OmniLight3D:
				child.owner = null
				child.reparent(scene.get_node("SetDressing"),false)
				child.name = "CeilingFill"
				child.omni_range = 7.0
		scene.set_script(load("res://scripts/room_art_template.gd"))
		scene.set_meta("purpose","Editable room template used by room_catalog.tres")
		save(scene,path)
	quit()

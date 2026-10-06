extends Node3D

func prepare_for_gameplay() -> void:
	var bedroom := get_node("Bedroom")
	# Replace only the two side-wall slabs with real doorway openings.
	for mesh in bedroom.get_node("OriginalScene").find_children("*", "MeshInstance3D", true, false):
		if absf(mesh.position.z) > 4.0 and mesh.mesh.get_surface_count() > 0:
			var mat = mesh.mesh.surface_get_material(0)
			if mat and mat.resource_name == "粉": mesh.visible = false
	var wall := StandardMaterial3D.new()
	wall.albedo_color = bedroom.wall_base_color
	wall.roughness = 1.0
	for side in [-1, 1]:
		for spec in [[Vector3(0.12,4.4,5.06),Vector3(side*4.98,2.2,-0.88)], [Vector3(0.12,4.4,0.46),Vector3(side*4.98,2.2,3.18)], [Vector3(0.12,1.85,1.3),Vector3(side*4.98,3.475,2.3)]]:
			var panel := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = spec[0]
			panel.mesh = box
			panel.material_override = wall
			panel.position = spec[1]
			add_child(panel)
	for name in ["OriginalCamera", "BedroomEnvironment", "DreamGrade"]:
		var helper := bedroom.get_node_or_null(name)
		if helper:
			helper.get_parent().remove_child(helper)
			helper.free()
	for camera in bedroom.find_children("*", "Camera3D", true, false):
		camera.get_parent().remove_child(camera)
		camera.free()

func door_position(direction: int) -> Vector3:
	return Vector3(direction * 5.0, 0, 2.3)

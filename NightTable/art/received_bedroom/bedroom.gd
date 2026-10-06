@tool
extends Node3D

@export var wall_base_color := Color("ed93b2")
@export var ceiling_base_color := Color("cf7f9c")

func _ready() -> void:
	# glTF light intensities use physical units; this scene supplies adapted lights.
	var imported := get_node_or_null("OriginalScene")
	if imported:
		# Local matte overrides preserve the imported source materials.
		for mesh in find_children("*", "MeshInstance3D", true, false):
			for surface in range(mesh.mesh.get_surface_count()):
				var source_material := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
				if source_material:
					var matte := source_material.duplicate() as StandardMaterial3D
					matte.metallic = 0.0
					matte.roughness = 1.0
					matte.metallic_specular = 0.0
					matte.normal_enabled = false
					# Walls and ceiling share the imported material but have separate editable colors.
					if source_material.resource_name == "粉":
						matte.albedo_texture = null
						matte.albedo_color = ceiling_base_color if mesh.position.y >= 3.5 else wall_base_color
					mesh.set_surface_override_material(surface, matte)
		for light in imported.find_children("*", "Light3D", true, false):
			light.visible = false
		for camera in imported.find_children("*", "Camera3D", true, false):
			camera.current = false
		for television in imported.find_children("tripo_node_a95563b2*", "MeshInstance3D", true, false):
			for surface in range(television.mesh.get_surface_count()):
				var original := television.mesh.surface_get_material(surface) as StandardMaterial3D
				if original and original.albedo_texture:
					var phosphor := ShaderMaterial.new()
					phosphor.shader = load("res://art/received_bedroom/tv_phosphor.gdshader")
					phosphor.set_shader_parameter("albedo_map", original.albedo_texture)
					television.set_surface_override_material(surface, phosphor)
	var render_camera := get_node_or_null("OriginalCamera") as Camera3D
	if render_camera:
		render_camera.make_current()

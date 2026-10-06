extends "res://scripts/exploration_room.gd"
## Gameplay-only adaptation; standalone art remains untouched.
@export var left_leaf: NodePath
@export var right_leaf: NodePath
@export var unit_scale := 1.0

func _prepare_geometry() -> void:
	if _geometry_prepared:return
	_geometry_prepared=true
	var art=get_node("Art")
	var materials={}
	# Procedural paper/floor patterns stay attached to the authored room when it moves.
	for mesh in art.find_children("*","MeshInstance3D",true,false):
		for i in mesh.mesh.get_surface_count():
			var original=mesh.get_active_material(i)
			if original is ShaderMaterial and "MODEL_MATRIX" in original.shader.code:
				var key=original.get_instance_id()
				if not materials.has(key):
					var copy=original.duplicate()
					var shader=Shader.new()
					shader.code=original.shader.code.replace("MODEL_MATRIX","(room_art_inverse*MODEL_MATRIX)").replace("MODEL_NORMAL_MATRIX","(mat3(room_art_inverse)*MODEL_NORMAL_MATRIX)").replace("shader_type spatial;","shader_type spatial;\nuniform mat4 room_art_inverse;")
					copy.shader=shader
					copy.set_shader_parameter("room_art_inverse",art.global_transform.affine_inverse())
					materials[key]=copy
				if mesh.material_override:mesh.material_override=materials[key]
				else:mesh.set_surface_override_material(i,materials[key])
	for light in art.find_children("*","Light3D",true,false):
		if light is OmniLight3D:light.omni_range*=unit_scale
		if light is SpotLight3D:light.spot_range*=unit_scale
	for direction in [-1,1]:
		var point=definition.door(direction)
		var doorway=Node3D.new()
		doorway.name="LeftDoor" if direction<0 else "RightDoor"
		add_child(doorway)
		doorway.position=Vector3(point.x,definition.floor_y,point.y)
		var hinge=Node3D.new()
		hinge.name="Hinge"
		doorway.add_child(hinge)
		hinge.position.z=-definition.door_width/2
		var leaf=art.get_node_or_null(left_leaf if direction<0 else right_leaf) as MeshInstance3D
		var height=2.6*unit_scale
		if leaf:
			var bounds: AABB=global_transform.affine_inverse()*leaf.global_transform*leaf.mesh.get_aabb()
			height=bounds.size.y
			leaf.global_position+=global_basis*(Vector3(point.x,definition.floor_y+height/2,point.y)-bounds.get_center())
			leaf.reparent(hinge,true)
		else:
			leaf=MeshInstance3D.new()
			var mesh=BoxMesh.new()
			mesh.size=Vector3(.07,height,definition.door_width)
			var mat=StandardMaterial3D.new()
			mat.albedo_color=Color("594532")
			mesh.material=mat
			leaf.mesh=mesh
			hinge.add_child(leaf)
			leaf.position=Vector3(0,height/2,definition.door_width/2)
		# Cut authored walls at the actual traversable portal, keeping their UV/materials.
		for mesh in art.find_children("*","MeshInstance3D",true,false):
			if not mesh.visible:continue
			var b: AABB=global_transform.affine_inverse()*mesh.global_transform*mesh.mesh.get_aabb()
			if b.size.y<.25 or b.position.y>height or absf(b.get_center().x-point.x)>.65:continue
			if b.end.z<point.y-definition.door_width/2 or b.position.z>point.y+definition.door_width/2:continue
			if b.size.z>definition.door_width and b.size.x<.7:
				for segment in [Vector2(b.position.z,point.y-definition.door_width/2),Vector2(point.y+definition.door_width/2,b.end.z),Vector2(point.y-definition.door_width/2,point.y+definition.door_width/2)]:
					if segment.y-segment.x<.001:continue
					var top=segment==Vector2(point.y-definition.door_width/2,point.y+definition.door_width/2)
					var bottom=height+definition.floor_y if top else b.position.y
					if b.end.y-bottom<=.001:continue
					var panel=MeshInstance3D.new()
					panel.name="PortalWall"
					panel.mesh=BoxMesh.new()
					panel.mesh.size=Vector3(b.size.x+.04,b.end.y-bottom,segment.y-segment.x)
					add_child(panel)
					panel.position=Vector3(b.get_center().x,(bottom+b.end.y)/2,(segment.x+segment.y)/2)
					preload("res://scripts/room_wall_surface.gd").apply(mesh,panel)
			mesh.hide()


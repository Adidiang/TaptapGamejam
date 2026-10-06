@tool
extends Node3D
## The source bedroom stays editable; only gameplay helpers are changed at runtime.
@export var definition: ExplorationRoomDefinition
var _geometry_prepared := false

func _ready() -> void:
	if not Engine.is_editor_hint() and get_parent()==get_tree().root:
		_prepare_geometry()
		for direction in [-1,1]:
			var door := get_node_or_null("LeftDoor" if direction<0 else "RightDoor")
			if door: door.get_node("Hinge").rotation.y = direction*deg_to_rad(100)

func prepare_for_gameplay() -> void:
	_prepare_geometry()
	# Standalone previews own their filter; gameplay applies one viewport-wide pass.
	for filter_node in find_children("*","CanvasLayer",true,false):
		filter_node.free()
	for helper in find_children("*","Camera3D",true,false)+find_children("*","WorldEnvironment",true,false):
		helper.free()

func _prepare_geometry() -> void:
	if _geometry_prepared: return
	_geometry_prepared = true
	var banquet := get_node_or_null("Banquet")
	if banquet:
		for direction in [-1,1]:
			var suffix := "_001" if direction<0 else ""
			var wall: MeshInstance3D = banquet.get_node("Layout/立方体_003" if direction<0 else "Layout/立方体_004")
			for part in ["BackWall","FrontWall","Lintel"]:
				preload("res://scripts/room_wall_surface.gd").apply(wall,get_node(("LeftDoor" if direction<0 else "RightDoor")+part))
			wall.visible=false
			var leaf: Node3D = banquet.get_node("Layout/Obj3d66-18249362-93-883"+suffix)
			leaf.reparent(get_node(("LeftDoor" if direction<0 else "RightDoor")+"/Hinge"),true)
	var bedroom := get_node_or_null("Bedroom")
	if bedroom:
		var source := bedroom.get_node("FurnitureAndArchitecture")
		var wall: MeshInstance3D = source.get_node("立方体_004")
		wall.visible = false
		for panel in get_node("DoorWall").get_children():
			panel.material_override = wall.get_active_material(0)
		var leaf: Node3D = source.get_node("Obj3d66-18249362-93-883")
		get_node("RightDoor/Hinge/Leaf").free()
		leaf.reparent(get_node("RightDoor/Hinge"),true)

func preview_environment() -> Environment:
	var environments := find_children("*","WorldEnvironment",true,false)
	return environments[0].environment if not environments.is_empty() else null

func preview_filter() -> ShaderMaterial:
	for layer in find_children("*","CanvasLayer",true,false):
		for rect in layer.find_children("*","ColorRect",true,false):
			if rect.material is ShaderMaterial:return rect.material
	return null

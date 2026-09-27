extends Node3D
const PAINT_STYLE = preload("res://art/rendering/painterly_profile.tres")
## Author furniture and local lights in the .tscn. Only preview helpers are removed at runtime.
@export var gameplay_offset := Vector3(0, 0, 1.6)
@export_node_path("Node3D") var left_door_preview := NodePath("Architecture/LeftDoorPreview")
@export_node_path("Node3D") var right_door_preview := NodePath("Architecture/RightDoorPreview")

func _ready() -> void:
	PAINT_STYLE.apply_to(self)

func prepare_for_gameplay() -> void:
	position += gameplay_offset
	for path in [left_door_preview, right_door_preview, NodePath("PreviewRig/PreviewCamera"), NodePath("PreviewRig/Environment"), NodePath("PreviewRig/SoftFill")]:
		var helper := get_node_or_null(path)
		if helper != null:
			helper.get_parent().remove_child(helper)
			helper.free()

func door_position(direction: int) -> Vector3:
	var anchor := get_node("FutureGameplayAnchors/LeftDoor" if direction < 0 else "FutureGameplayAnchors/RightDoor") as Node3D
	return anchor.position

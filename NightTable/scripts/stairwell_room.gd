@tool
extends "res://scripts/exploration_room.gd"

func _prepare_geometry() -> void:
	if _geometry_prepared:return
	_geometry_prepared=true
	# Hide inherited whitebox grid strips across the stair opening.
	for child in get_children():
		if child is MeshInstance3D and (child.name=="GridX" or str(child.name).begins_with("@")):
			child.hide()

func configure_stairs(links: Array) -> void:
	var up=false
	var down=false
	for link in links:
		up=up or link.direction>0
		down=down or link.direction<0
	$UpStairs.visible=up
	$DownStairs.visible=down
	$UnusedDownCover.visible=not down

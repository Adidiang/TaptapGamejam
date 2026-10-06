class_name ExplorationRoomDefinition
extends Resource
## All positions use room-local X/Z. Bounds describe floor space before actor radius.
@export_file("*.tscn") var scene_path: String
@export var display_name: String
@export var floor_bounds := Rect2(-4.5,-3,9,6)
@export var floor_y := 0.1
@export var spawn := Vector2(0,1)
@export var interaction := Vector2(0,0.5)
@export var left_door := Vector2(-4.5,-1.346)
@export var right_door := Vector2(4.5,-1.346)
@export var door_width := 1.227
@export var has_left_door := true
@export var has_right_door := true
@export var obstacles: Array[Rect2] = []
@export var camera_position := Vector3(1.0476923,2.1739657,7.4098067)
@export var camera_pitch := -1.201
@export var camera_fov := 45.74733
## Optional authored Camera3D endpoints, relative to the room scene root.
@export var camera_left_anchor: NodePath
@export var camera_right_anchor: NodePath

func door(direction: int) -> Vector2:
	return left_door if direction<0 else right_door

func arrival(direction: int) -> Vector2:
	return door(direction)+Vector2(-direction*0.65,0)

func has_door(direction: int) -> bool:
	return has_left_door if direction<0 else has_right_door

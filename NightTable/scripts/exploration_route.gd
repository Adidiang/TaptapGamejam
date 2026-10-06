class_name ExplorationRoute
extends Resource
## Seeded category selection; event templates are selected in a second roll.
@export var bedroom: ExplorationRoomDefinition
@export var whitebox: ExplorationRoomDefinition
@export var banquet: ExplorationRoomDefinition
@export var battle: ExplorationRoomDefinition
@export var events: Array[ExplorationRoomDefinition] = []
@export_range(4,32) var initial_rooms := 8
@export_range(0,100) var battle_weight := 25
@export_range(0,100) var shop_weight := 10
@export_range(0,100) var event_weight := 65

@export var stairwell: ExplorationRoomDefinition
@export var queen: ExplorationRoomDefinition
## Temporary map inspection: allow leaving uncleared combat rooms.
@export var debug_unlock_combat_doors := false

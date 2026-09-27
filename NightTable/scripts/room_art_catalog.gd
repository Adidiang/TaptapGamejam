extends Resource
## Swap whole room scenes here without modifying the map generator.
@export var battle_room: PackedScene
@export var event_room: PackedScene
@export var shop_room: PackedScene
@export var spawn_room: PackedScene
@export var boss_room: PackedScene
@export var doorway: PackedScene
@export var ladder: PackedScene

func scene_for(kind: String) -> PackedScene:
	match kind:
		"event": return event_room
		"shop": return shop_room
		"spawn": return spawn_room if spawn_room != null else battle_room
		"boss": return boss_room if boss_room != null else battle_room
		_: return battle_room

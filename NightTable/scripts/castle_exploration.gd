class_name CastleExploration
extends RefCounted
## Room-local navigation survives UI recreation. Rendering never owns run progress.
const PLAYER_RADIUS := 0.18
var layout: Dictionary
var current := -1
var player_x := 0.0
var player_z := 0.0
var player_height := 0.1
var in_battle := false
var in_dialogue := false
var overview := false
var relics: Array[String] = []

func start(seed_value: int, populate: bool = false) -> void:
	layout = CastleGenerator.generate(seed_value)
	if populate: RoomContent.populate(layout,seed_value)
	current = layout.spawn
	player_height=definition().floor_y
	_set_local(definition().spawn)
	in_battle = false
	in_dialogue = false
	overview = false

func room() -> Dictionary:
	return layout.rooms[current]

func definition() -> ExplorationRoomDefinition:
	return room().definition

func local_position() -> Vector2:
	return Vector2(player_x-room().column*CastleGenerator.ROOM_WIDTH,player_z)

func _set_local(value: Vector2) -> void:
	player_x = room().column*CastleGenerator.ROOM_WIDTH+value.x
	player_z = value.y

func connected_rooms(id: int) -> Array:
	var result: Array = []
	for other in layout.rooms[id].neighbors:
		if id in layout.rooms[other].neighbors: result.append(other)
	return result

func room_visibility(id: int) -> int:
	if layout.rooms[id].seen: return 2
	for other in connected_rooms(id):
		if layout.rooms[other].seen: return 1
	return 0

func locked() -> bool:
	if CastleGenerator.ROUTE.debug_unlock_combat_doors: return false
	return room().kind in ["encounter","boss"] and not room().cleared

func can_pass(from: int, to: int) -> bool:
	return to in connected_rooms(from)

func port(direction: int) -> Dictionary:
	for link in room().get("ports",[]):
		if link.side==direction and absf(player_height-definition().floor_y-link.level*CastleGenerator.FLOOR_HEIGHT)<.18:return link
	# Compatibility for isolated art inspection fixtures.
	if not room().has("ports"):
		for id in connected_rooms(current):
			if layout.rooms[id].floor==room().floor and layout.rooms[id].column==room().column+direction:
				return {"to":id,"side":direction,"level":0,"to_level":0}
	return {}

func neighbor(direction: int) -> int:
	return port(direction).get("to",-1)

func _enter(id: int, from_direction: int = 0, level: int = 0) -> void:
	current=id
	room().seen=true
	player_height=definition().floor_y+level*CastleGenerator.FLOOR_HEIGHT
	_set_local(definition().spawn if from_direction==0 else definition().arrival(from_direction))

func _walk_to(point: Vector2) -> bool:
	if room().kind=="stairs":
		var height := StairGeometry.height_at(point,player_height)
		if is_nan(height):return false
		player_height=height
		_set_local(point)
		return true
	if _blocked(point):return false
	_set_local(point)
	return true

func _blocked(point: Vector2) -> bool:
	for obstacle in definition().obstacles:
		if obstacle.grow(PLAYER_RADIUS).has_point(point): return true
	return false

func move(distance: float, depth: float = 0.0) -> void:
	if in_battle or in_dialogue: return
	# Small axis-separated steps slide along furniture instead of tunnelling through it.
	var steps := maxi(1,int(ceil(Vector2(distance,depth).length()/0.08)))
	var increment := Vector2(distance,depth)/steps
	for index in range(steps):
		var spec := definition()
		var point := local_position()
		var next := point
		next.y = clampf(point.y+increment.y,spec.floor_bounds.position.y+PLAYER_RADIUS,spec.floor_bounds.end.y-PLAYER_RADIUS)
		if _walk_to(next): point = next
		next = point+Vector2(increment.x,0)
		var direction := 1 if increment.x>0 else -1
		var destination := neighbor(direction)
		var door := spec.door(direction)
		var aligned := absf(next.y-door.y)<=spec.door_width/2-PLAYER_RADIUS
		var passage := destination>=0 and spec.has_door(direction) and aligned and not locked()
		if passage and direction*(next.x-door.x)>=0:
			_enter(destination,-direction,int(port(direction).get("to_level",0)))
			# One transition per call, with a safe arrival inside the destination.
			return
		var margin := 0.0 if passage else PLAYER_RADIUS
		next.x = clampf(next.x,spec.floor_bounds.position.x+margin,spec.floor_bounds.end.x-margin)
		if _walk_to(next): point = next
		_set_local(point)

func available_interaction() -> Dictionary:
	if in_battle or in_dialogue: return {}
	if room().kind=="stairs":return {}
	if local_position().distance_to(definition().interaction)>1.3: return {}
	if room().kind in ["event","shop"] and (room().kind=="shop" or not room().get("completed",false)):
		return {"type":"content"}
	if room().kind in ["encounter","boss"] and not room().cleared and not room().triggered:
		return {"type":"battle","room":current}
	return {}

func interact() -> String:
	var action := available_interaction()
	if action.is_empty(): return ""
	if action.type=="content": return "content"
	room().triggered = true
	in_battle = true
	return "battle"

func complete_room() -> void:
	if not in_battle: return
	room().cleared = true
	in_battle = false

func cleared_count() -> int:
	var count := 0
	for entry in layout.rooms:
		if entry.cleared and entry.kind!="spawn": count += 1
	return count


func nearby_rooms(depth: int = 2) -> Array:
	var result: Array=[current]
	var frontier: Array=[current]
	for layer in depth:
		var next: Array=[]
		for id in frontier:
			for neighbor_id in connected_rooms(id):
				if neighbor_id not in result:
					result.append(neighbor_id)
					next.append(neighbor_id)
		frontier=next
	return result

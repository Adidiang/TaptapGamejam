class_name CastleExploration
extends RefCounted
## Persistent exploration state, independent of 3D rendering and battle UI lifetime.
var layout: Dictionary
var current := -1
var player_x := 0.0
var in_battle := false
var in_dialogue := false
var overview := false
var relics: Array[String] = []

func start(seed_value: int, populate: bool = false) -> void:
	layout = CastleGenerator.generate(seed_value)
	if populate: RoomContent.populate(layout,seed_value)
	current = layout.spawn
	player_x = room().column*CastleGenerator.ROOM_WIDTH
	in_battle = false
	in_dialogue = false
	overview = false

func room() -> Dictionary:
	return layout.rooms[current]

## Explicit passage graph only; spatial adjacency never implies a connection.
func connected_rooms(id: int) -> Array:
	var entry: Dictionary = layout.rooms[id]
	var result: Array = []
	# neighbors stores actual horizontal door links, not nearby coordinates.
	for neighbor in entry.neighbors:
		if id in layout.rooms[neighbor].neighbors: result.append(neighbor)
	for ladder_id in entry.ladders:
		var ladder: Dictionary = layout.ladders[ladder_id]
		if ladder.get("hidden",false) and not layout.get("clock_started",false): continue
		if id not in [ladder.lower,ladder.upper]: continue
		var other: int = ladder.upper if ladder.lower==id else ladder.lower
		if ladder_id in layout.rooms[other].ladders and other not in result: result.append(other)
	return result

## 0: unknown, 1: connected frontier (type only), 2: explored interior.
func room_visibility(id: int) -> int:
	if layout.rooms[id].seen: return 2
	for other in connected_rooms(id):
		if layout.rooms[other].seen: return 1
	return 0

func locked() -> bool:
	return room().kind in ["encounter","boss"] and not room().cleared

func can_pass(from: int, to: int) -> bool:
	var copper: Dictionary = layout.get("copper",{})
	return copper.is_empty() or copper.open or not (from in [copper.a,copper.b] and to in [copper.a,copper.b])

func _enter(id: int) -> void:
	current = id
	room().seen = true

func move(distance: float) -> void:
	if in_battle or in_dialogue: return
	# Small bounded steps prevent tunnelling across an uncleared room.
	var remaining := distance
	while absf(remaining)>0.0001:
		var step := clampf(remaining,-0.25,0.25)
		remaining -= step
		var center: float = room().column*CastleGenerator.ROOM_WIDTH
		var desired := player_x+step
		var edge := CastleGenerator.ROOM_WIDTH/2.0
		if locked():
			player_x = clampf(desired,center-edge+0.65,center+edge-0.65)
			continue
		if absf(desired-center)>edge:
			var column: int = room().column+(1 if step>0 else -1)
			var destination := -1
			for id in room().neighbors:
				if layout.rooms[id].column==column: destination = id
			if destination<0 or not can_pass(current,destination):
				player_x = clampf(desired,center-edge+0.65,center+edge-0.65)
				continue
			_enter(destination)
			var new_center: float = room().column*CastleGenerator.ROOM_WIDTH
			player_x = clampf(desired,new_center-edge+0.7,new_center+edge-0.7)
		else: player_x = desired

func available_interaction() -> Dictionary:
	if in_battle or in_dialogue: return {}
	var center: float = room().column*CastleGenerator.ROOM_WIDTH
	var copper: Dictionary = layout.get("copper",{})
	if not copper.is_empty() and not copper.open and current in [copper.a,copper.b] and absf(player_x+15)<1.5:
		return {"type":"unlock","ready":"R08" in relics}
	if current==layout.get("clock_room",-1) and not layout.clock_started and room().get("completed",false) and absf(player_x-center)<1.5:
		return {"type":"clock","ready":"R09" in relics}
	if room().kind in ["event","shop"] and absf(player_x-center)<1.5 and (room().kind=="shop" or not room().get("completed",false)):
		return {"type":"content"}
	if locked():
		if not room().triggered and absf(player_x-room().column*CastleGenerator.ROOM_WIDTH)<1.5:
			return {"type":"battle","room":current}
		return {}
	var best := 1.3
	var interaction := {}
	for id in room().ladders:
		var ladder: Dictionary = layout.ladders[id]
		if ladder.get("hidden",false) and not layout.get("clock_started",false): continue
		var distance := absf(player_x-ladder.x)
		if distance<best:
			best = distance
			interaction = {"type":"ladder","id":id,"up":ladder.lower==current}
	return interaction

func interact() -> String:
	var action := available_interaction()
	if action.is_empty(): return ""
	if action.type=="content": return "content"
	if action.type in ["unlock","clock"]:
		if not action.ready: return ""
		if action.type=="unlock": layout.copper.open = true
		else: layout.clock_started = true
		return action.type
	if action.type=="battle":
		room().triggered = true
		in_battle = true
		return "battle"
	var ladder: Dictionary = layout.ladders[action.id]
	_enter(ladder.upper if ladder.lower==current else ladder.lower)
	player_x = ladder.x
	return "ladder"

func complete_room() -> void:
	if not in_battle: return
	room().cleared = true
	in_battle = false

func cleared_count() -> int:
	var count := 0
	for entry in layout.rooms:
		if entry.cleared and entry.kind!="spawn": count += 1
	return count

class_name CastleGenerator
extends RefCounted
## Topology first: contiguous rows, overlapping vertical pairs, deterministic seed.
const ROOM_WIDTH := 10.0
const FLOOR_HEIGHT := 6.5
const FLOOR_NAMES := ["地下室","一层","二层","王座层"]

static func generate(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var width := rng.randi_range(4,6)
	var ranges: Array = []
	ranges.append(Vector2i(rng.randi_range(0,1),width-rng.randi_range(1,2)))
	ranges.append(Vector2i(0,width-1))
	ranges.append(Vector2i(rng.randi_range(0,1),width-rng.randi_range(1,2)))
	var boss_column := rng.randi_range(ranges[2].x,ranges[2].y)
	ranges.append(Vector2i(boss_column,boss_column))
	var rooms: Array = []
	var lookup := {}
	var rows: Array = [[],[],[],[]]
	for floor_index in range(4):
		for column in range(ranges[floor_index].x,ranges[floor_index].y+1):
			var id := rooms.size()
			var kind := "boss" if floor_index==3 else ("spawn" if floor_index==1 and column==0 else "encounter")
			rooms.append({"id":id,"floor":floor_index,"column":column,"kind":kind,"neighbors":[],"ladders":[],"cleared":kind=="spawn","triggered":false,"seen":kind=="spawn","style":rng.randi_range(0,2)})
			lookup[Vector2i(column,floor_index)] = id
			rows[floor_index].append(id)
	for room in rooms:
		var right := Vector2i(room.column+1,room.floor)
		if lookup.has(right):
			room.neighbors.append(lookup[right])
			rooms[lookup[right]].neighbors.append(room.id)
	var ladders: Array = []
	for floor_index in range(3):
		var overlaps: Array[int] = []
		for column in range(width):
			if lookup.has(Vector2i(column,floor_index)) and lookup.has(Vector2i(column,floor_index+1)): overlaps.append(column)
		var count := mini(overlaps.size(),rng.randi_range(1,2)) if floor_index<2 else 1
		for i in range(count):
			var chosen := rng.randi_range(0,overlaps.size()-1)
			var column := overlaps[chosen]
			overlaps.remove_at(chosen)
			var lower: int = lookup[Vector2i(column,floor_index)]
			var upper: int = lookup[Vector2i(column,floor_index+1)]
			var id := ladders.size()
			ladders.append({"id":id,"lower":lower,"upper":upper,"x":column*ROOM_WIDTH+(-2.5 if floor_index%2==0 else 2.5)})
			rooms[lower].ladders.append(id)
			rooms[upper].ladders.append(id)
	return {"seed":seed_value,"width":width,"rooms":rooms,"rows":rows,"ladders":ladders,"spawn":lookup[Vector2i(0,1)],"boss":rows[3][0]}

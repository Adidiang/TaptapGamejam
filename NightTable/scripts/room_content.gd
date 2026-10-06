class_name RoomContent
extends RefCounted
## Only contents are seeded. Population never adds branches or changes room topology.
static func populate(layout: Dictionary, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 98371
	for room in layout.rooms:
		if room.has("offers"): continue
		rng.seed=seed_value ^ (98371+int(room.id)*7919)
		room.offers = []
		room.completed = room.kind=="spawn"
		if room.kind=="shop":
			room.offers = cards(rng,3,15)+relics(rng,2,40)
		elif room.kind=="event":
			var reward := rng.randi_range(0,1)
			room.offers = [{"type":"points","amount":20}] if room.column==2 else (cards(rng,3,0) if reward==0 else relics(rng,2,0))

static func cards(rng: RandomNumberGenerator, count: int, cost: int) -> Array:
	var pool := RunInventory.pool()
	var result: Array = []
	for i in range(count):
		var index := rng.randi_range(0,pool.size()-1)
		result.append({"type":"card","card":pool[index],"cost":cost})
		pool.remove_at(index)
	return result

static func relics(rng: RandomNumberGenerator, count: int, cost: int) -> Array:
	var pool: Array = ["R01","R02","R03","R04","R05","R06","R07"]
	var result: Array = []
	for i in range(count):
		var index := rng.randi_range(0,pool.size()-1)
		result.append({"type":"relic","id":pool[index],"cost":cost})
		pool.remove_at(index)
	return result

class_name RoomContent
extends RefCounted
## Seeded room contents are generated once; UI never rolls rewards or stock.
static func populate(layout: Dictionary, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 98371
	var shop_count := 1 # Reserve the guaranteed ground-floor shop.
	for room in layout.rooms:
		room.offers = []
		room.completed = room.kind=="spawn"
		if room.kind in ["spawn","boss"]: continue
		if room.floor==1 and room.column==1: continue
		var roll := rng.randf()
		room.kind = "encounter" if roll<0.6 else ("event" if roll<0.9 or shop_count>=2 else "shop")
		if room.floor==1 and room.column==2: room.kind = "event"
		if room.floor==1 and room.column==3: room.kind = "shop"
		if room.kind=="shop" and not (room.floor==1 and room.column==3): shop_count += 1
		if room.kind in ["event","shop"]:
			room.cleared = true
			if room.kind=="shop":
				room.offers = cards(rng,3,15)+relics(rng,2,40)
			else:
				var reward := rng.randi_range(0,2)
				if room.floor==1 and room.column==2: reward = 2
				room.offers = cards(rng,3,0) if reward==0 else (relics(rng,2,0) if reward==1 else [{"type":"points","amount":20}])
	# Optional branch lies left of spawn, never on the ordinary Boss route.
	# Guarantee a second ordinary reward node in addition to the currency event.
	var extra: Dictionary = layout.rooms[layout.rows[2][0]]
	extra.kind = "event"
	extra.cleared = true
	extra.offers = cards(rng,3,0) if rng.randf()<0.5 else relics(rng,2,0)
	var key := _room(layout,-1,1,"铜钥匣",[{"type":"relic","id":"R08"}])
	var gear := _room(layout,-2,1,"钟机房",[{"type":"relic","id":"R09"}])
	var altar := _room(layout,-2,2,"无名祭坛",[{"type":"relic","id":"R10"}])
	layout.rooms[layout.spawn].neighbors.append(key)
	layout.rooms[key].neighbors.assign([layout.spawn,gear])
	layout.rooms[gear].neighbors.append(key)
	layout.copper = {"a":key,"b":gear,"open":false}
	layout.clock_room = gear
	layout.clock_started = false
	var ladder_id: int = layout.ladders.size()
	layout.ladders.append({"id":ladder_id,"lower":gear,"upper":altar,"x":-22.5,"hidden":true})
	layout.rooms[gear].ladders.append(ladder_id)
	layout.rooms[altar].ladders.append(ladder_id)

static func _room(layout: Dictionary, column: int, floor_index: int, title: String, offers: Array) -> int:
	var id: int = layout.rooms.size()
	layout.rooms.append({"id":id,"floor":floor_index,"column":column,"kind":"event","neighbors":[],"ladders":[],"cleared":true,"triggered":false,"seen":false,"style":0,"completed":false,"title":title,"offers":offers})
	layout.rows[floor_index].append(id)
	return id

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

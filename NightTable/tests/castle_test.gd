extends RefCounted
var check: Callable

func neighbors(layout: Dictionary, id: int) -> Array:
	var result: Array = layout.rooms[id].neighbors.duplicate()
	for ladder_id in layout.rooms[id].ladders:
		var ladder: Dictionary = layout.ladders[ladder_id]
		result.append(ladder.upper if ladder.lower==id else ladder.lower)
	return result

func test(verify: Callable) -> void:
	check = verify
	for seed_value in range(200):
		var map := CastleGenerator.generate(seed_value)
		var fog_state := CastleExploration.new()
		fog_state.start(seed_value)
		var frontier := neighbors(map,map.spawn)
		for entry in map.rooms:
			var expected := 2 if entry.id==map.spawn else (1 if entry.id in frontier else 0)
			check.call(fog_state.room_visibility(entry.id)==expected,"initial fog reveals only actual door and ladder neighbors")
		check.call(map==CastleGenerator.generate(seed_value),"castle seed reproducible")
		var queue: Array = [map.spawn]
		var visited := {}
		while not queue.is_empty():
			var id: int = queue.pop_front()
			if visited.has(id): continue
			visited[id] = true
			queue.append_array(neighbors(map,id))
		check.call(visited.size()==map.rooms.size(),"all rooms and boss reachable")
		check.call(map.rooms[map.spawn].floor==1 and map.rooms[map.boss].floor==3 and map.rows[3].size()==1,"spawn and boss floors")
		for floor_index in range(3):
			var count := 0
			for ladder in map.ladders:
				if map.rooms[ladder.lower].floor==floor_index: count += 1
			check.call(count in [1,2],"one or two vertical links per adjacent floor")
		for ladder in map.ladders:
			var lower: Dictionary = map.rooms[ladder.lower]
			var upper: Dictionary = map.rooms[ladder.upper]
			check.call(upper.floor==lower.floor+1 and upper.column==lower.column,"paired ladder coordinates")
		for room in map.rooms:
			for id in room.neighbors:
				check.call(map.rooms[id].floor==room.floor and abs(map.rooms[id].column-room.column)==1 and room.id in map.rooms[id].neighbors,"horizontal doors adjacent and reciprocal")
	var exploration := CastleExploration.new()
	# Four touching rooms: only explicit passages may reveal their interiors' shells.
	var passage_state := CastleExploration.new()
	passage_state.layout = {"rooms":[
		{"seen":true,"floor":1,"column":0,"neighbors":[],"ladders":[]},
		{"seen":false,"floor":1,"column":1,"neighbors":[],"ladders":[]},
		{"seen":false,"floor":2,"column":0,"neighbors":[],"ladders":[]},
		{"seen":false,"floor":0,"column":0,"neighbors":[],"ladders":[]}
	],"ladders":[]}
	for id in [1,2,3]: check.call(passage_state.room_visibility(id)==0,"touching rooms without passages remain hidden")
	passage_state.layout.rooms[0].neighbors.append(1)
	passage_state.layout.rooms[1].neighbors.append(0)
	check.call(passage_state.room_visibility(1)==1,"real door reveals adjacent room")
	passage_state.layout.ladders.append({"lower":0,"upper":2})
	passage_state.layout.rooms[0].ladders.append(0)
	passage_state.layout.rooms[2].ladders.append(0)
	check.call(passage_state.room_visibility(2)==1 and passage_state.room_visibility(3)==0,"ladder reveals only its actual other endpoint")
	passage_state.layout.rooms[0].neighbors.clear()
	passage_state.layout.rooms[1].neighbors.clear()
	check.call(passage_state.room_visibility(1)==0,"removing door hides unexplored room despite unchanged position")
	exploration.start(217)
	var spawn := exploration.current
	check.call(not exploration.locked() and exploration.interact()!="battle","spawn safe and no battle marker")
	exploration.move(6)
	var first := exploration.current
	check.call(exploration.room_visibility(first)==2 and exploration.room_visibility(spawn)==2,"entering lights room and retains explored spawn")
	for id in neighbors(exploration.layout,first):
		check.call(exploration.room_visibility(id)>=1,"new room reveals its direct connections")
	check.call(first!=spawn and exploration.locked(),"entering fresh room locks it")
	exploration.move(100)
	check.call(exploration.current==first,"cannot tunnel through uncleared room")
	exploration.move(-100)
	check.call(exploration.current==first,"cannot retreat through locked entry")
	check.call(exploration.interact()=="","battle requires proximity")
	for ladder_id in exploration.room().ladders:
		exploration.player_x = exploration.layout.ladders[ladder_id].x
		check.call(exploration.interact()=="" and exploration.current==first,"ladders locked during encounter")
	exploration.player_x = exploration.room().column*CastleGenerator.ROOM_WIDTH
	check.call(exploration.interact()=="battle" and exploration.room().triggered,"F starts battle and removes marker")
	var location := exploration.player_x
	exploration.move(30)
	check.call(exploration.player_x==location and exploration.interact()=="","no movement or duplicate battle during combat")
	exploration.complete_room()
	check.call(not exploration.locked() and exploration.interact()!="battle","completion unlocks and never retriggers")
	exploration.move(-10)
	check.call(exploration.current==spawn,"can revisit spawn")
	check.call(exploration.room_visibility(first)==2,"exploration remains visible after leaving")
	exploration.move(10)
	check.call(exploration.current==first and not exploration.locked(),"cleared room remains open")
	for ladder in exploration.layout.ladders:
		var state := CastleExploration.new()
		state.start(217)
		state.current = ladder.lower
		state.room().cleared = true
		state.player_x = ladder.x
		check.call(state.interact()=="ladder" and state.current==ladder.upper and state.locked(),"ladder up locks destination")
		state.move(state.room().column*CastleGenerator.ROOM_WIDTH-state.player_x)
		check.call(state.interact()=="battle","upstairs marker usable after ladder entry")
		state.complete_room()
		state.move(ladder.x-state.player_x)
		check.call(state.interact()=="ladder" and state.current==ladder.lower and not state.locked(),"same ladder returns down to cleared room")
	# Walk generated graphs through model movement/ladders, clearing battles via run adapter.
	for seed_value in range(30):
		var profile := MemoryProfile.new()
		profile.persistence = false
		var run := NightRun.new()
		run.begin(seed_value,profile,true)
		var state := run.castle
		var parent := {state.current:-1}
		var queue: Array = [state.current]
		while not queue.is_empty():
			var id: int = queue.pop_front()
			for next in neighbors(state.layout,id):
				if not parent.has(next):
					parent[next] = id
					queue.append(next)
		var path: Array = []
		var cursor: int = state.layout.boss
		while cursor!=state.current:
			path.push_front(cursor)
			cursor = parent[cursor]
		for destination in path:
			var target: Dictionary = state.layout.rooms[destination]
			if target.floor==state.room().floor:
				state.move(target.column*CastleGenerator.ROOM_WIDTH-state.player_x)
			else:
				for ladder_id in state.room().ladders:
					var ladder: Dictionary = state.layout.ladders[ladder_id]
					if destination in [ladder.lower,ladder.upper]:
						state.move(ladder.x-state.player_x)
						check.call(state.interact()=="ladder","F ladder traversal")
						break
			check.call(state.current==destination,"follow connected room route")
			if target.kind not in ["encounter","boss"]:
				check.call(not state.locked(),"events and shops do not lock travel")
				continue
			state.move(target.column*CastleGenerator.ROOM_WIDTH-state.player_x)
			check.call(state.interact()=="battle" and run.start_castle_encounter(),"room connects to existing encounter state")
			check.call(not run.start_castle_encounter(),"encounter entry idempotent")
			run.hp = 100
			run.finish_node()
			check.call(target.cleared and not state.in_battle,"battle return clears same room")
		check.call(not run.active and run.ending=="dawn","single top-floor boss completes castle")

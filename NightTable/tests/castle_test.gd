extends RefCounted
var check: Callable

static func test_seed(start: int = 0) -> int:
	for value in range(start, start+10000):
		var rooms: Array = CastleGenerator.generate(value).rooms
		if rooms[0].kind=="spawn" and rooms[1].column==1 and rooms[2].column==2 and rooms[3].column==3 and rooms[1].kind=="encounter" and rooms[2].kind=="event" and rooms[3].kind=="shop":
			return value
	return -1

static func center(state: CastleExploration) -> void:
	state.move(-state.local_position().x)
	state.move(0,state.definition().interaction.y-state.player_z)

static func travel(state: CastleExploration, direction: int = 1) -> void:
	# An actual walk: first align depth with the door, then cross the boundary.
	state.move(0,state.definition().door(direction).y-state.player_z)
	state.move(direction*10.0)
	center(state)

func test(verify: Callable) -> void:
	check = verify
	for seed_value in range(30):
		var map := CastleGenerator.generate(seed_value)
		check.call(map==CastleGenerator.generate(seed_value),"linear route reproducible")
		check.call(map.rows.size() in [4,5] and map.ladders.is_empty(),"three or four floors with no ladder shortcuts")
		check.call(map.rooms[map.spawn].column==map.spans[map.rooms[map.spawn].floor].x and map.rooms[map.spawn].floor in [0,1] and map.rooms[map.spawn].neighbors.size()==1 and map.rooms[map.spawn].ports[0].side==1,"bedroom has only right connection on lower floors")
		var exploration := CastleExploration.new()
		exploration.start(seed_value,true)
		check.call(exploration.layout.rooms.size()==map.rooms.size(),"content never adds legacy branches")
		for room in map.rooms:
			check.call(room.column>=0 and room.column<map.width and room.floor<map.floors,"room coordinates lie in castle footprint")
			for id in room.neighbors:
				check.call(room.id in map.rooms[id].neighbors,"reciprocal adjacent doors or stairs")
			check.call(exploration.room_visibility(room.id)==(2 if room.id==map.spawn else (1 if room.id in map.rooms[map.spawn].neighbors else 0)),"only linked frontier initially visible")
	var state := CastleExploration.new()
	state.start(test_seed(),true)
	var before := state.local_position()
	state.move(0,-0.5)
	check.call(state.local_position().is_equal_approx(before+Vector2(0,-0.5)),"forward changes depth")
	state.move(0,0.5)
	check.call(state.local_position().is_equal_approx(before),"backward restores depth")
	state.move(10)
	check.call(state.current==0 and state.local_position().x<0.81,"bed blocks travel at front")
	state.move(0,-2.346)
	state.move(0.5,0.1)
	check.call(state.local_position().x>1.0,"rear gap permits walking around bed")
	state._enter(0)
	state.move(0,-100)
	check.call(state.player_z>=-2.82,"back wall bounds movement")
	state.move(-100)
	check.call(state.current==0 and state.local_position().x>=-4.32,"no left exit in starting bedroom")
	state._enter(0)
	travel(state)
	check.call(state.current==1 and state.locked(),"actual rear doorway enters encounter")
	var encounter := state.current
	state.move(0,state.definition().left_door.y-state.player_z)
	state.move(-100)
	check.call(state.current==encounter,"locked entry prevents retreat")
	state.move(100)
	check.call(state.current==encounter,"large step cannot skip locked combat")
	check.call(state.interact()=="","interaction requires proximity in two dimensions")
	center(state)
	check.call(state.interact()=="battle" and state.in_battle,"central marker starts battle")
	before = state.local_position()
	state.move(1,1)
	check.call(state.local_position()==before and state.interact()=="","battle blocks navigation and retrigger")
	state.complete_room()
	check.call(not state.locked(),"battle completion unlocks doors")
	state.in_dialogue = true
	state.move(-1,-1)
	check.call(state.local_position()==before,"dialogue blocks both axes")
	state.in_dialogue = false
	travel(state,-1)
	check.call(state.current==0 and state.room_visibility(1)==2,"rear doorway returns to bedroom and retains history")
	travel(state)
	check.call(state.current==1 and not state.locked(),"revisiting cleared room does not relock")
	travel(state)
	check.call(state.current==2 and state.interact()=="content","event uses whitebox central marker")
	travel(state)
	check.call(state.current==3 and state.interact()=="content","shop remains connected")

	# Vary the next template's doorway depth: entry must use its own anchor.
	state._enter(2)
	var alternate: ExplorationRoomDefinition = state.layout.rooms[3].definition.duplicate()
	alternate.left_door.y = 1.7
	state.layout.rooms[3].definition = alternate
	state.move(0,state.definition().right_door.y-state.player_z)
	state.move(10)
	check.call(state.current==3 and is_equal_approx(state.player_z,1.7),"arrival uses destination-specific doorway depth")
	check.call(not state._blocked(state.local_position()),"arrival clears collision geometry")


	# Reach the queen through the graph, including actual staircase interactions.
	for seed_value in range(30):
		var profile := MemoryProfile.new()
		profile.persistence=false
		var run := NightRun.new()
		run.begin(seed_value,profile,true)
		state=run.castle
		var parents={state.current:-1}
		var queue: Array=[state.current]
		while not queue.is_empty():
			var id: int=queue.pop_front()
			for neighbor_id in state.connected_rooms(id):
				if not parents.has(neighbor_id):
					parents[neighbor_id]=id
					queue.append(neighbor_id)
		check.call(parents.size()==state.layout.rooms.size(),"all castle rooms reachable")
		var path: Array=[]
		var cursor: int=state.layout.boss
		while cursor!=state.current:
			path.push_front(cursor)
			cursor=parents[cursor]
		for destination in path:
			var target: Dictionary=state.layout.rooms[destination]
			load("res://tests/castle_navigation.gd").cross(state,destination)
			check.call(state.current==destination,"navigation follows castle graph")
			if state.locked():
				state._set_local(state.definition().interaction)
				check.call(state.interact()=="battle" and run.start_castle_encounter(),"battle enters from room")
				run.hp=100
				run.finish_node()
		check.call(not run.active and run.ending=="dawn","queen victory finishes castle run")

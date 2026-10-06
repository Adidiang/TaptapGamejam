extends SceneTree
var failures:=0
func check(value: bool,label: String):
	if not value:failures+=1;push_error(label)
func _initialize():call_deferred("run_checks")
func run_checks():
	var shapes={}
	for seed_value in 1000:
		var map=CastleGenerator.generate(seed_value)
		check(map==CastleGenerator.generate(seed_value),"reproducible castle")
		check(map.floors in [4,5],"four or five floors")
		check(map.rows[-1]==[map.boss],"crown has only queen room")
		check(map.rooms[map.spawn].floor in [0,1],"bedroom on lower two floors")
		var occupied={}
		var reached=[map.spawn]
		var frontier=[map.spawn]
		while not frontier.is_empty():
			var id=frontier.pop_front()
			for next in map.rooms[id].neighbors:
				if next not in reached:reached.append(next);frontier.append(next)
		check(reached.size()==map.rooms.size(),"all rooms and queen reachable")
		var counts={}
		for room in map.rooms:
			for level in room.height_floors:
				var cell=Vector2i(room.column,room.floor+level)
				check(not occupied.has(cell),"two-storey stairwell never overlaps room")
				occupied[cell]=room.id
			if room.kind=="stairs":counts[room.floor]=counts.get(room.floor,0)+1
			for port in room.ports:
				var target=map.rooms[port.to]
				check(target.column==room.column+port.side and target.floor+port.to_level==room.floor+port.level,"doors align horizontally and vertically")
				check(target.ports.any(func(p):return p.to==room.id and p.level==port.to_level and p.side==-port.side),"reciprocal landing door")
		for f in range(map.floors-1):
			check(counts.get(f,0) in [1,2] if f==0 else counts.get(f,0)==1,"only lowest floor pair may have two stair halls")
		for shaft in map.stairs:
			for other in map.stairs:
				if shaft.room==other.room:continue
				check(absi(shaft.floor-other.floor)>1 or absi(shaft.column-other.column)>1,"stair halls never touch on a shared storey")
		shapes[str(map.spans)]=true
	check(shapes.size()>100,"varied tapered castle silhouettes")
	if "--layout-only" in OS.get_cmdline_user_args():
		print("CASTLE_LAYOUT_FAILURES ",failures)
		quit(0 if failures==0 else 1)
		return
	var state=CastleExploration.new()
	state.start(0,true)
	var stair_id: int=state.layout.stairs[-1].room
	state._enter(stair_id)
	for entry in state.layout.rooms:entry.seen=true
	var view=CastleView.new()
	view.configure(state)
	root.size=Vector2i(1600,900)
	root.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.set_process(false)
	view.focused=false
	await process_frame
	view._snap_camera()
	view._sync()
	check(state.interact()=="","F no longer teleports upstairs")
	await capture("stairwell_lower")
	var id_before=state.current
	state.move(0,1.35-state.player_z)
	state.move(3.4-state.local_position().x)
	check(absf(state.player_height-3.35)<.02,"first flight reaches halfway landing")
	check(state.current==id_before,"first flight remains in same physical room")
	view._sync()
	for frame in 160:view._process(.016)
	await capture("stairwell_halfway")
	state.move(0,-1.35-state.player_z)
	state.move(-3.75-state.local_position().x)
	check(absf(state.player_height-6.6)<.02,"second flight reaches upper storey")
	check(state.current==id_before,"second flight remains in same physical room")
	check(state.neighbor(-1)>=0 or state.neighbor(1)>=0,"upper floor has usable exit")
	view._sync()
	for frame in 160:view._process(.016)
	await capture("stairwell_upper")
	load("res://tests/castle_navigation.gd").stair_level(state,0)
	check(absf(state.player_height-.1)<.02,"walk down both flights without teleport")
	view._sync()
	for frame in 160:view._process(.016)
	state.overview=true
	view._sync()
	await process_frame
	view.minimap._sync()
	view.minimap._snap_camera()
	await capture("castle_map")
	view.queue_free()
	await process_frame
	print("CASTLE_LAYOUT_FAILURES ",failures)
	quit(1 if failures else 0)
func capture(label: String):
	if DisplayServer.get_name()=="headless":return
	for frame in 12:await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("F:/gamejam/outputs/castle_layout")
	root.get_texture().get_image().save_png("F:/gamejam/outputs/castle_layout/"+label+".png")

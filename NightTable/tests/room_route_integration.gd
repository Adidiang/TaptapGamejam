extends SceneTree
var failures=0
func check(value:bool,label:String):
	if not value:
		failures+=1
		push_error(label)
func _initialize():call_deferred("run_checks")
func run_checks():
	var types={}
	var events={}
	for seed_value in 100:
		var a=CastleGenerator.generate(seed_value)
		check(a==CastleGenerator.generate(seed_value),"seed reproducible")
		for entry in a.rooms:
			types[entry.kind]=true
			if entry.kind=="event":events[entry.definition.scene_path]=true
			if entry.kind=="encounter":check(entry.definition==CastleGenerator.ROUTE.battle,"battle uses armory")
			if entry.kind=="shop":check(entry.definition==CastleGenerator.ROUTE.whitebox,"shop uses whitebox")
	check(types.size()==6 and events.size()==5,"all categories and all five events reachable")
	var state=CastleExploration.new()
	state.start(217,true)
	var specs=[CastleGenerator.ROUTE.bedroom,CastleGenerator.ROUTE.battle,CastleGenerator.ROUTE.whitebox]+Array(CastleGenerator.ROUTE.events)
	state.layout.rooms.resize(specs.size())
	state.layout.width=specs.size()
	state.layout.floors=1
	state.layout.stairs=[]
	state.layout.spawn=0
	state.current=0
	state._set_local(specs[0].spawn)
	for i in specs.size():
		state.layout.rooms[i].erase("ports")
		state.layout.rooms[i].height_floors=1
		state.layout.rooms[i].floor=0
		state.layout.rooms[i].column=i
		state.layout.rooms[i].stairs=[]
		state.layout.rooms[i].neighbors=([i-1] if i>0 else [])+([i+1] if i<specs.size()-1 else [])
		state.layout.rooms[i].definition=specs[i]
		state.layout.rooms[i].kind="spawn" if i==0 else ("encounter" if i==1 else ("shop" if i==2 else "event"))
		state.layout.rooms[i].cleared=i!=1
	root.size=Vector2i(1600,900)
	var view=CastleView.new()
	view.configure(state)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(view)
	view.set_process(false)
	view.focused=false
	await process_frame
	for i in range(1,specs.size()):
		var deadline=Time.get_ticks_msec()+60000
		while view.room_visuals[i].art==null and Time.get_ticks_msec()<deadline:
			view._pump_room_stream()
			await create_timer(.01).timeout
		check(view.room_visuals[i].art!=null,"destination prepared before crossing")
		var blocking_before=view.synchronous_room_loads
		state.move(0,state.definition().right_door.y-state.player_z)
		state.move(10)
		check(state.current==i,"walk through aligned portal %d"%i)
		var before=view.camera.position
		var crossing_start=Time.get_ticks_usec()
		view._sync()
		print("CROSSING_MS ",i," ",(Time.get_ticks_usec()-crossing_start)/1000.0)
		check(view.synchronous_room_loads==blocking_before,"crossing performs no synchronous resource load")
		check(view.camera.position.is_equal_approx(before),"camera never snaps during switch")
		check(not state._blocked(state.local_position()),"arrival has no collision")
		var art=view.room_visuals[i].art
		check(art!=null,"room art loaded")
		check(art.find_children("*","CanvasLayer",true,false).is_empty(),"no stacked postprocessing")
		check(art.find_children("*","Camera3D",true,false).is_empty(),"one gameplay camera")
		for side in [-1,1]:
			var door=art.get_node("LeftDoor" if side<0 else "RightDoor")
			check(is_equal_approx(door.position.z,-1.346),"portal Z aligned")
			check(door.get_node("Hinge").get_child_count()>0,"door leaf present")
		if i==1:
			state.move(10)
			check(state.current==1,"battle locks exit")
			state.move(-state.local_position().x)
			check(state.interact()=="battle","armory interaction starts combat")
			state.complete_room()
			check(not state.locked(),"combat reward return unlocks room")
		state.move(-state.local_position().x)
		view._sync()
		for frame in 160:view._process(1.0/60.0)
		check(view.camera.position.distance_to(view._camera_target())<.04,"camera eases to target")
		if DisplayServer.get_name()!="headless":
			for frame in 8:await process_frame
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute("F:/gamejam/outputs/route_integration")
			root.get_texture().get_image().save_png("F:/gamejam/outputs/route_integration/room_%d.png"%i)
		print("VERIFIED_ROOM ",i," ",specs[i].scene_path)
	check(state.layout.width==8,"castle route is finite")
	var offer=state.layout.rooms[2].offers.duplicate(true)
	RoomContent.populate(state.layout,int(state.layout.seed))
	check(state.layout.rooms[2].offers==offer,"extension preserves existing offers")
	for i in range(6,-1,-1):
		state.move(0,state.definition().left_door.y-state.player_z)
		state.move(-10)
		check(state.current==i,"return through left portal %d"%i)
	view.queue_free()
	await process_frame
	print("ROOM_ROUTE_FAILURES ",failures)
	quit(1 if failures else 0)

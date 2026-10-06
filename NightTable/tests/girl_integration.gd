extends SceneTree
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run_checks")
func run_checks() -> void:
	var girl = load("res://art/characters/girl/girl.tscn").instantiate()
	root.add_child(girl)
	await process_frame
	girl.set_process(false)
	var player: AnimationPlayer = girl.animation_player
	check(player != null, "girl has animation player")
	check(player.has_animation("Idle") and player.has_animation("Run01"), "both retargeted clips imported")
	for name in ["Idle", "Run01"]:
		var clip := player.get_animation(name)
		var morphs := 0
		for track in clip.get_track_count():
			if clip.track_get_type(track)==Animation.TYPE_BLEND_SHAPE: morphs+=1
		check(morphs==0, "body clips do not overwrite spring-controlled hair: "+name)
		check(clip.loop_mode==Animation.LOOP_LINEAR, "clip loops: "+name)
	girl.update_locomotion(Vector2.RIGHT, 1.0)
	check(player.current_animation=="Run01", "movement starts Run01")
	check(absf(girl.rotation.y-PI/2)<.01, "character faces right")
	var hair: MeshInstance3D = girl.find_child("Hair", true, false)
	check(hair != null and hair.mesh.get_blend_shape_count()==8, "wave and gravity morph mesh imported")
	for frame in 120:girl._process(1.0/60.0)
	check(girl._hair_lift>.9, "running raises hair gradually")
	var first := hair.get_blend_shape_value(1)
	for frame in 15:girl._process(1.0/60.0)
	check(absf(first-hair.get_blend_shape_value(1))>.01, "vertex waves actually animate")
	girl.update_locomotion(Vector2.ZERO, .1)
	check(player.current_animation=="Idle", "stopping returns to Idle")
	check(girl._hair_lift>.8, "hair does not snap to rest when stopping")
	for frame in 180:girl._process(1.0/60.0)
	check(absf(girl._hair_lift)<.001, "hair settles after stopping")
	check(absf(hair.get_blend_shape_value(girl._hair_shapes["Gravity_Rest"])-1.0)<.001, "settled hair returns to downward rest shape")
	girl.queue_free()
	await process_frame
	if "--render" in OS.get_cmdline_user_args():
		var state := CastleExploration.new()
		state.start(0, true)
		var view := CastleView.new()
		view.configure(state)
		root.size=Vector2i(1600,900)
		root.add_child(view)
		view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		view.focused=false
		for frame in 60: await process_frame
		check(view.actor_visual != null, "main exploration uses girl")
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("F:/gamejam/outputs/girl_integration")
		root.get_texture().get_image().save_png("F:/gamejam/outputs/girl_integration/bedroom.png")
		view.queue_free()
		await process_frame
	print("GIRL_INTEGRATION_FAILURES ",failures)
	quit(1 if failures else 0)

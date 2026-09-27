extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	if not "--smoke" in OS.get_cmdline_user_args():
		push_error("Run with -- --smoke so screenshots cannot write player saves.")
		quit(1)
		return
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.curtain.duration = 0.025
	await app.start_run(217)
	var state = app.run.castle
	for title in ["spawn","battle","event","shop"]:
		if title!="spawn": state.move(10.0)
		var view = app.page.get_node("CastleView")
		view._snap_camera()
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/room_studies/in_game_"+title+".png")
		print("CAPTURED ",title," kind=",state.room().kind)
		if title=="battle":
			assert(state.interact()=="battle")
			state.complete_room()
	for side in [-1,1]:
		state.player_x = state.room().column*CastleGenerator.ROOM_WIDTH+side*4.35
		app.page.get_node("CastleView")._snap_camera()
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/room_studies/in_game_edge_%s.png" % side)
	quit()

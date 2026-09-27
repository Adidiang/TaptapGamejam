extends SceneTree
## 相机探针：实例化白盒场景，打印横板相机运行时的真实参数和构图实测。
## 用法：Godot --headless --path NightTable --script res://tests/cam_probe.gd

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/level1_whitebox.tscn")
	if packed == null:
		push_error("FAIL: 场景加载失败")
		quit(1)
		return
	var board: Node = packed.instantiate()
	root.add_child(board)
	# 等几帧，让 _ready / _process / _physics_process 都跑起来
	for i in range(8):
		await process_frame

	var cam: Camera3D = board.get("side_camera")
	var player: CharacterBody3D = board.get("player")
	if cam == null or player == null:
		push_error("FAIL: side_camera=%s player=%s" % [cam, player])
		quit(1)
		return

	print("== 相机参数（运行时实测）==")
	print("projection   = %d (0=perspective 1=orthogonal)" % cam.projection)
	print("size         = %.2f" % cam.size)
	print("keep_aspect  = %d (0=keep_width 1=keep_height)" % cam.keep_aspect)
	print("rotation_deg = %s" % cam.rotation_degrees)
	print("position     = %s" % cam.position)
	print("global_pos   = %s" % cam.global_position)
	print("current      = %s" % cam.current)
	print("== 玩家 ==")
	print("player pos   = %s  velocity = %s" % [player.position, player.velocity])

	var vp_size: Vector2 = cam.get_viewport().get_visible_rect().size
	print("== 视口 ==")
	print("viewport     = %s  aspect = %.3f" % [vp_size, vp_size.x / vp_size.y])

	# 用 unproject 实测构图：各关键点落在画面高度的百分比（0=底 100=顶）
	var vp_h := vp_size.y
	var fh: float = board.get("FLOOR_H")
	var points := {
		"玩家脚底 (z=3)": Vector3(player.position.x, 0.0, 3.0),
		"玩家头顶 (z=3)": Vector3(player.position.x, 1.7, 3.0),
		"墙脚线 (z=-5)": Vector3(player.position.x, 0.0, -5.0),
		"2F楼板前缘 (z=+5)": Vector3(0.0, fh, 5.0),
		"2F楼板后缘 (z=-5)": Vector3(0.0, fh, -5.0),
		"2F标签 (z=0)": Vector3(0.0, fh + 3.0, 0.0),
		"1F标签 (z=0)": Vector3(0.0, 3.0, 0.0),
		"墙顶 (y=FLOOR_H,z=-5)": Vector3(player.position.x, fh, -5.0),
	}
	print("== 构图实测（画面高度百分比，0=底 100=顶）==")
	for key in points.keys():
		var p: Vector3 = points[key]
		var s: Vector2 = cam.unproject_position(p)
		var pct := (vp_h * 0.5 - s.y) / vp_h * 100.0 + 50.0
		print("  %-26s y=%5.1f%%" % [key, pct])
	quit(0)

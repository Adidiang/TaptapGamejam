extends SceneTree
## 渲染截图探针：真实渲染（非无头）白盒场景 30 帧后截图存盘。
## 用法：Godot --path NightTable --script res://tests/shot_scene.gd

const OUT := "C:/Users/12579/AppData/Local/Temp/whitebox_shot.png"

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
	for i in range(30):
		await process_frame
	var img: Image = root.get_texture().get_image()
	img.save_png(OUT)
	print("SAVED: %s  size=%s" % [OUT, img.get_size()])
	quit(0)

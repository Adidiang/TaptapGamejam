extends SceneTree
## 渲染 lighting_studio.tscn，确认工作室场景能正确加载并显示灯光后处理。

const OUT := "C:/Users/12579/AppData/Local/Temp/studio_shot.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/lighting_studio.tscn")
	if packed == null:
		print("FATAL: studio load failed")
		quit(1)
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	for i in range(20):
		await process_frame
	if scene.has_signal("ready"):
		await process_frame
	# 选 SideCam 并预览
	var cam: Camera3D = scene.get_node("SideCam")
	cam.make_current()
	for i in range(15):
		await process_frame
	var img: Image = root.get_texture().get_image()
	img.save_png(OUT)
	print("SAVED: ", OUT, " size=", img.get_size())
	quit(0)
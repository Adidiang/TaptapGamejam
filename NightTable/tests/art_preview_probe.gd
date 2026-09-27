extends SceneTree
## 渲染 art_preview.tscn 看它现在长什么样，并打印场景树结构确认骑士是否混入。

const OUT := "C:/Users/12579/AppData/Local/Temp/art_preview_shot.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/art_preview.tscn")
	if packed == null:
		push_error("FAIL: art_preview.tscn 加载失败")
		quit(1)
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	for i in range(30):
		await process_frame

	# 打印场景树（前 3 层）
	print("=== art_preview 场景树 ===")
	_print_tree(scene, 0, 3)

	# 找到相机并打印参数
	var cam := _find_node(scene, "SideCam") as Camera3D
	if cam:
		print("=== SideCam ===")
		print("projection = ", cam.projection, " (0=persp 1=ortho)")
		print("fov = ", cam.fov)
		print("size = ", cam.size)
		print("position = ", cam.global_position)
		print("rotation_deg = ", cam.global_rotation_degrees)
		cam.make_current()

	# 统计 Model 子节点数（确认骑士混入）
	var model := _find_node(scene, "Model")
	if model:
		var count := 0
		var stack: Array = [model]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			if n is MeshInstance3D:
				count += 1
			stack.append_array(n.get_children())
		print("=== Model 下的 MeshInstance3D 数量 = ", count, " ===")

	root.get_texture().get_image().save_png(OUT)
	print("SAVED: ", OUT)
	quit(0)

func _print_tree(node: Node, depth: int, max_depth: int) -> void:
	if depth > max_depth:
		return
	var indent := ""
	for i in range(depth):
		indent += "  "
	var extra := ""
	if node is MeshInstance3D:
		extra = " [Mesh]"
	elif node is Camera3D:
		extra = " [Camera]"
	elif node is Light3D:
		extra = " [Light]"
	print("%s%s%s" % [indent, node.name, extra])
	for child in node.get_children():
		_print_tree(child, depth + 1, max_depth)

func _find_node(node: Node, name: String) -> Node:
	if node.name == name:
		return node
	for child in node.get_children():
		var found := _find_node(child, name)
		if found:
			return found
	return null

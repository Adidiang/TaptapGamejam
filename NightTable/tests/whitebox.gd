extends SceneTree
## 校验脚本：确认 Level 1 白盒能实例化，且房间数量与设计图配比一致。
## 用法：Godot --headless --path NightTable --script res://tests/whitebox.gd

var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		push_error("FAIL: " + message)
		quit(1)
		assert(condition, message)
	print("  ok  " + message)

func _run() -> void:
	var packed: PackedScene = load("res://scenes/level1_whitebox.tscn")
	check(packed != null, "白盒场景可加载")
	if packed == null:
		quit(1)
		return
	var board: Node = packed.instantiate()
	check(board != null, "场景可实例化")
	root.add_child(board)

	var texts: Array = []
	var meshes := 0
	var bodies := 0
	var labels := 0
	_walk(board, texts, [meshes, bodies, labels])
	meshes = _count_of(board, "MeshInstance3D")
	bodies = _count_of(board, "StaticBody3D")
	labels = _count_of(board, "Label3D")

	var f1 := 0
	var f2 := 0
	var kinds := {"ENCOUNTER": 0, "EVENT": 0, "INVESTIGATE": 0, "SHOP": 0}
	var markers := {"STAIR TO 2F": 0, "SHOP STAIR": 0, "ONE-WAY GATE": 0, "STAIR TO TOP": 0}
	for t in texts:
		var text := String(t)
		if text.begins_with("1F-"):
			f1 += 1
		if text.begins_with("2F-"):
			f2 += 1
		for key in kinds.keys():
			if text.ends_with(String(key)):
				kinds[key] = int(kinds[key]) + 1
		for key in markers.keys():
			if text == String(key):
				markers[key] = int(markers[key]) + 1

	check(f1 == 8, "一楼 8 格（6 普通房 + 2 商店），实际 %d" % f1)
	check(f2 == 6, "二楼 6 格，实际 %d" % f2)
	check(int(kinds["ENCOUNTER"]) == 6, "战斗房间共 6 间（一楼 3 + 二楼 3），实际 %d" % int(kinds["ENCOUNTER"]))
	check(int(kinds["EVENT"]) == 4, "事件房间共 4 间（一楼 2 + 二楼 2），实际 %d" % int(kinds["EVENT"]))
	check(int(kinds["INVESTIGATE"]) == 2, "调查房间共 2 间（每层 1），实际 %d" % int(kinds["INVESTIGATE"]))
	check(int(kinds["SHOP"]) == 2, "商店 2 间（一楼左右各 1），实际 %d" % int(kinds["SHOP"]))
	check(int(markers["STAIR TO 2F"]) == 1, "大堂主楼梯 1 部")
	check(int(markers["SHOP STAIR"]) == 2, "两个商店各有 1 部上楼楼梯")
	check(int(markers["STAIR TO TOP"]) == 1, "通往顶层的楼梯 1 部")
	check(int(markers["ONE-WAY GATE"]) == 1, "顶层的单向门 1 处")

	var cameras := 0
	var characters := 0
	for child in board.get_children():
		if child is CharacterBody3D:
			characters += 1
	cameras = _count_of(board, "Camera3D")
	check(characters == 1, "第一人称角色存在")
	check(cameras == 2, "相机 2 台（横板 + 第一人称），实际 %d" % cameras)
	check(meshes > 150, "几何体已生成（%d 个 MeshInstance3D）" % meshes)
	check(bodies > 60, "碰撞体已生成（%d 个 StaticBody3D）" % bodies)

	print("白盒校验通过：%d 项检查" % checks)
	print("统计：mesh=%d body=%d label=%d" % [meshes, bodies, labels])
	quit(0)

func _count_of(node: Node, kind: String) -> int:
	var total := 0
	for child in node.get_children():
		if child.is_class(kind):
			total += 1
		total += _count_of(child, kind)
	return total

func _walk(node: Node, texts: Array, counters: Array) -> void:
	for child in node.get_children():
		if child is Label3D:
			texts.append((child as Label3D).text)
		_walk(child, texts, counters)

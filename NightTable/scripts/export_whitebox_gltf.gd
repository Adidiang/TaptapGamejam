extends SceneTree
## 把 Level 1 白盒导出成 glTF 2.0（.glb），交给 DCC（Blender / Maya / 3ds Max）继续做。
##
## 为什么导出而不是直接给 .tscn：DCC 不认 Godot 场景。glTF 2.0 是唯一「三家都吃得下、
## 还带 PBR 材质和米制单位」的交换格式 —— Godot 1 单位 = 1 米 = glTF 1 单位 = Blender 1 米，
## 不用换算。
##
## 导出的东西做了一次整理，否则 DCC 里就是 255 个无名方块：
##   1. 只留 MeshInstance3D —— 碰撞体 / 灯光 / 相机 / 标签全去掉（DCC 不需要物理）
##   2. 按房间标签分组（就近归属），outliner 里是「1F-01 ENCOUNTER」这样的组，
##      可以直接按房间选中、替换成正式模型
##   3. 没归属的（走廊、楼梯、门框）统一进 STRUCTURE 组
##
## 无头跑：
##   Godot --headless --path NightTable --script res://scripts/export_whitebox_gltf.gd
## 出口路径可用环境变量覆盖：GODOT_WB_OUT=C:/some/where.glb

const SCENE_PATH := "res://scenes/level1_whitebox.tscn"
const DEFAULT_OUT := "res://../exports/level1_whitebox.glb"

## 归属半径：mesh 到房间标签在这个范围内就算这个房间的。
## 房间 9×11 m，取 12 m 刚好覆盖整间房又不至于把走廊墙全吸进来。
const CLAIM_RADIUS := 12.0

const GROUP_FALLBACK := "STRUCTURE"

## 分层的树：Level1Whitebox > [1F / 2F / TOP] > 房间组。
## 必须先分层 —— Boss 房压在二楼大堂正上方，X/Z 完全重叠，只比距离的话
## 二楼大堂的标签永远更近，Boss 房会被整个吃掉。
const FLOOR_NAMES := {1: "1F", 2: "2F", 3: "TOP"}

## 楼梯和大门天生跨层，它们的标签对所有层都可见，否则一段楼梯会被劈成两半。
const CROSS_FLOOR_TOKENS := ["STAIR", "GATE"]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load(SCENE_PATH)
	if packed == null:
		push_error("找不到场景：" + SCENE_PATH)
		quit(1)
		return
	var whitebox: Node3D = packed.instantiate()
	# 必须挂进场景树才会触发 _ready —— 几何是在 _ready 里生成的。
	root.add_child(whitebox)

	var out_path := _resolve_out_path()
	DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())

	var assembled := _assemble(whitebox)
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_scene(assembled, state)
	if err != OK:
		push_error("append_from_scene 失败，错误码 %d" % err)
		quit(1)
		return
	var bytes := doc.generate_buffer(state)
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	if file == null:
		push_error("写不进去：" + out_path)
		quit(1)
		return
	file.store_buffer(bytes)
	file.close()

	print("已导出：%s" % ProjectSettings.globalize_path(out_path))
	print("大小 %.1f KB" % (bytes.size() / 1024.0))
	print("mesh %d 个" % _count(assembled, "MeshInstance3D"))
	for floor_node in assembled.get_children():
		print("  [%s]" % floor_node.name)
		for group in floor_node.get_children():
			print("    - %s (%d)" % [group.name, group.get_child_count()])
	assembled.free()
	whitebox.free()
	quit(0)


## res://../ 这种路径 FileAccess 认，但 ProjectSettings 不认，这里自己拼。
func _resolve_out_path() -> String:
	var custom := OS.get_environment("GODOT_WB_OUT")
	if custom != "":
		return custom
	if not DEFAULT_OUT.begins_with("res://"):
		return DEFAULT_OUT
	var project_root := ProjectSettings.globalize_path("res://")
	return project_root.path_join(DEFAULT_OUT.substr(6)).simplify_path()


## 整理成一棵干净的树：剥掉非几何节点，先分层、再按房间标签分组。
func _assemble(source: Node3D) -> Node3D:
	# 注意 find_children 的第四个参数 owned 默认是 true，而白盒的几何是代码 add_child
	# 出来的、owner 为空 —— 不显式传 false 会一个都找不到。
	var labels: Array = []
	for node in source.find_children("*", "Label3D", true, false):
		var text := String(node.text)
		var cross := false
		for token in CROSS_FLOOR_TOKENS:
			if text.contains(token):
				cross = true
		labels.append({
			"pos": node.global_position,
			"text": text,
			"floor": _floor_of(node.global_position.y),
			"cross": cross,
		})

	var meshes: Array = source.find_children("*", "MeshInstance3D", true, false)

	var out := Node3D.new()
	out.name = "Level1Whitebox"
	var floors: Dictionary = {}
	var groups: Dictionary = {}
	var counter: Dictionary = {}
	for mesh in meshes:
		var node := mesh as MeshInstance3D
		var level := _floor_of(node.global_position.y)
		var best := ""
		var best_distance := CLAIM_RADIUS
		var fallback_best := ""
		var fallback_distance := INF
		for entry in labels:
			if not bool(entry.cross) and int(entry.floor) != level:
				continue
			var distance := node.global_position.distance_to(entry.pos as Vector3)
			# 跨层的楼梯/大门标签半径砍半 —— 它们只该认领自己附近那几级踏板，
			# 否则「GOLDEN GATE」会把整个 Boss 房都吸走。
			var radius := CLAIM_RADIUS * 0.5 if bool(entry.cross) else CLAIM_RADIUS
			if distance < radius and distance < best_distance:
				best_distance = distance
				best = String(entry.text)
			if distance < fallback_distance:
				fallback_distance = distance
				fallback_best = String(entry.text)
		# 半径内没人认领就用最近的那一个，别丢进 STRUCTURE —— DCC 里一串
		# 无名方块没法用。
		if best == "":
			best = fallback_best if fallback_best != "" else GROUP_FALLBACK

		var floor_node := _ensure_floor(out, floors, level)
		var key := "%d|%s" % [level, best]
		if not groups.has(key):
			var group := Node3D.new()
			group.name = best
			floor_node.add_child(group)
			groups[key] = group
			counter[key] = 0
		var index: int = counter[key] + 1
		counter[key] = index
		node.name = "%s_%03d" % [best, index]
		# reparent 会保留全局变换，方块不会跑位。
		node.reparent(groups[key], true)
	return out


## 按 mesh 中心高度判层。楼板中心在 base - 0.15，所以边界要压低一点。
func _floor_of(y: float) -> int:
	var floor_h := Level1Whitebox.FLOOR_H
	if y < floor_h - 0.5:
		return 1
	if y < floor_h * 2.0 - 0.5:
		return 2
	return 3


func _ensure_floor(root: Node3D, floors: Dictionary, level: int) -> Node3D:
	if not floors.has(level):
		var node := Node3D.new()
		node.name = String(FLOOR_NAMES.get(level, "L%d" % level))
		root.add_child(node)
		floors[level] = node
	return floors[level] as Node3D


func _count(node: Node, type: String) -> int:
	return node.find_children("*", type, true, false).size()

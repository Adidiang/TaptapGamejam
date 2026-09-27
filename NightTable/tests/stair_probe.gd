extends SceneTree
## 枚举楼梯上方所有「会投影的 mesh」：cast_shadow != OFF 且 AABB 在 y > 10。
## 这些就是 shadow map 里挡楼梯光的候选。

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/level1_whitebox.tscn")
	var board: Node = packed.instantiate()
	root.add_child(board)
	for i in range(10):
		await process_frame

	var found := 0
	var skipped := 0
	var stack: Array = [board]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var aabb := mi.global_transform * mi.get_aabb()
			var top_y := aabb.position.y + aabb.size.y
			if top_y > 10.0:
				var shadow := mi.cast_shadow
				var mesh_name := "no-mesh"
				if mi.mesh:
					mesh_name = mi.mesh.get_class()
				var line := "%s  mesh=%s top_y=%.1f cast_shadow=%d aabb=(%.1f,%.1f,%.1f)" % [
					mi.name, mesh_name, top_y, shadow,
					aabb.position.x, aabb.position.y, aabb.position.z]
				if shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
					print("投影中: " + line)
					found += 1
				else:
					skipped += 1
		stack.append_array(n.get_children())
	print("SUMMARY: 会投影且顶高于10m的mesh=%d，已关投影=%d" % [found, skipped])
	quit(0)

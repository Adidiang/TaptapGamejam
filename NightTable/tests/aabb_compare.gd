extends SceneTree
## 对比「glb 白盒」和「程序白盒」的包围盒，诊断坐标系/缩放差异。

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# glb 白盒（art_preview 用的）
	var packed_glb: PackedScene = load("res://art/whitebox.glb")
	var glb: Node3D = packed_glb.instantiate()
	root.add_child(glb)
	await process_frame
	await process_frame
	var aabb_g := _merged_aabb(glb)
	print("GLB  白盒: pos=%s size=%s" % [aabb_g.position, aabb_g.size])

	# 程序白盒
	var packed_prog: PackedScene = load("res://scenes/level1_whitebox.tscn")
	var prog: Node3D = packed_prog.instantiate()
	root.add_child(prog)
	await process_frame
	await process_frame
	var aabb_p := _merged_aabb(prog)
	print("程序 白盒: pos=%s size=%s" % [aabb_p.position, aabb_p.size])
	quit(0)

func _merged_aabb(node: Node3D) -> AABB:
	var merged := AABB()
	var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var ab := mi.global_transform * mi.get_aabb()
			if first:
				merged = ab
				first = false
			else:
				merged = merged.merge(ab)
		stack.append_array(n.get_children())
	return merged

extends Node3D
## art_preview 的收尾脚本。
##
## 为什么关掉 Model 里所有 mesh 的投影：
## glb 导入的 mesh（per-material 合并的大 mesh）在 Compatibility 渲染器的
## 正交阴影模式下会全员被自阴影吃掉——楼梯、人物、墙整片变黑，
## 调 shadow_bias 也救不回来（0.1/0.3/1.0 都试过）。关掉 cast_shadow 后
## 画面立刻恢复正常。level1 用的是代码生成的小 BoxMesh，不受影响，
## 所以 lighting_env.tscn 的 Sun 阴影保持开启给 level1 用。

func _ready() -> void:
	var model := get_node_or_null("Model")
	if model == null:
		return
	var count := 0
	var stack: Array = [model]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			(n as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			count += 1
		stack.append_array(n.get_children())
	if OS.is_debug_build() and not DisplayServer.get_name() == "headless":
		print("[art_preview] 已关闭 %d 个 glb mesh 的投影（Compatibility 自阴影规避）" % count)

extends SceneTree

func _initialize() -> void:
	call_deferred("merge_scene")

func localize(node: Node, scene: Node) -> void:
	if node != scene:
		node.owner = scene
		node.scene_file_path = ""
	for child in node.get_children():
		localize(child, scene)

func count_nodes(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += count_nodes(child)
	return total

func merge_scene() -> void:
	var path := "res://art/received_bedroom/bedroom.tscn"
	var scene := (load(path) as PackedScene).instantiate()
	var before := count_nodes(scene)
	localize(scene, scene)
	var packed := PackedScene.new()
	assert(packed.pack(scene) == OK)
	assert(ResourceSaver.save(packed, path) == OK)
	var check := (ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate()
	assert(count_nodes(check) == before)
	for child in check.find_children("*", "", true, false):
		assert(child.owner == check)
		assert(child.scene_file_path.is_empty())
	print("MERGED_EDITABLE_NODES ", before)
	check.free()
	scene.free()
	quit()

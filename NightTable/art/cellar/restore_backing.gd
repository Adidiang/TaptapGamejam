extends SceneTree
func _initialize(): call_deferred("fix")
func fix():
 var room=load("res://art/cellar/cellar.tscn").instantiate()
 for node in room.get_node("Architecture").get_children():
  if str(node.name).begins_with("RearStone") or str(node.name).begins_with("RearMortar"): node.position.z-=1.05
 var packed=PackedScene.new()
 packed.pack(room)
 ResourceSaver.save(packed,"res://art/cellar/cellar.tscn")
 room.free()
 quit()

extends SceneTree
func _initialize():
	call_deferred("inspect")
func inspect():
	var room = load("res://art/exploration/bedroom_room.tscn").instantiate()
	root.add_child(room)
	room.prepare_for_gameplay()
	assert(room.has_node("Bedroom/FurnitureAndArchitecture/ToyCubby"))
	assert(not room.has_node("Bedroom/RoomDressing"))
	for point in [Vector2(3.85,-1.346),Vector2(2.8,-1.35),Vector2(1.9,-1.35),Vector2(0,-1.35),Vector2(0,.5),Vector2(0,1)]:
		for obstacle in room.definition.obstacles:
			assert(not obstacle.grow(.18).has_point(point),"Dressing blocks movement: "+str(point))
	print("DRESSING_OK: scene loads, door prepares, entry and center clear with 0.18 clearance.")
	room.free()
	quit()

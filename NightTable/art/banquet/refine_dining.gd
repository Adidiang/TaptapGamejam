extends "res://art/banquet/dress_dining.gd"
func build():
	room=load("res://art/banquet/banquet.tscn").instantiate()
	root.add_child(room)
	dressing=room.get_node("DiningDecor")
	library=load("res://art/banquet/dining_assets/selected.glb").instantiate()
	# The extracted upper beam contains incomplete arches; replace with intact panel trim.
	for node in dressing.get_children():
		if "CarvedCornice" in node.name or "UpperCarving" in node.name: node.free()
	place("Wainscot","BackUpperTrim",Vector3(0,5.5,-11.65),Vector3(8.8,0.3,0.14))
	for side in [-1,1]:
		var suffix="Left" if side<0 else "Right"
		var yaw=-side*90.0
		for z in [-8.5,-4.6]:
			place("Curtain","SideDrapery_%s_%s"%[suffix,str(z)],Vector3(side*4.19,1.75,z),Vector3(2.85,3.7,0.32),yaw)
			place("Wainscot","UpperTrim_%s_%s"%[suffix,str(z)],Vector3(side*4.3,5.5,z),Vector3(3.9,0.3,0.15),yaw)
		var medallion=dressing.get_node("WallMedallion_"+suffix)
		medallion.position=TURN*Vector3(side*4.0,3.2,-6.55)
		var lamp=dressing.get_node("WallLamp_%s_-7_1"%suffix) if dressing.has_node("WallLamp_%s_-7_1"%suffix) else null
		# Godot sanitizes decimal points in node names.
		for node in dressing.get_children():
			if node.name.begins_with("WallLamp_"+suffix) or node.name.begins_with("WarmPool_"+suffix):
				var p=TURN.inverse()*node.position
				if p.z < -5: p.z=-6.6
				p.x=side*3.9
				node.position=TURN*p
	dressing.get_node("ForegroundChandelier").position=TURN*Vector3(0,3.9,-2.2)
	var packed=PackedScene.new()
	assert(packed.pack(room)==OK)
	assert(ResourceSaver.save(packed,"res://art/banquet/banquet.tscn")==OK)
	library.free()
	print("DINING_REFINED")
	quit()

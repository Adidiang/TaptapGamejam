extends SceneTree
func _initialize(): call_deferred("fix")
func fix():
 var scene=load("res://art/music_hall/music_hall.tscn").instantiate()
 root.add_child(scene)
 var piano=Node3D.new()
 piano.name="PianoAndBench"
 var bounds=AABB()
 var first=true
 for n in scene.get_node("Layout").find_children("*","MeshInstance3D",true,false):
  if str(n.name).begins_with("huitugou_7106"):
   for i in n.mesh.get_surface_count():
    var mat=n.get_active_material(i).duplicate()
    mat.metallic=0
    mat.normal_enabled=false
    mat.roughness=.35
    n.set_surface_override_material(i,mat)
   var b=n.global_transform*n.get_aabb()
   bounds=b if first else bounds.merge(b)
   first=false
   var copy=n.duplicate()
   piano.add_child(copy)
   copy.owner=piano
   copy.transform=n.global_transform
 var lamp=SpotLight3D.new()
 lamp.name="PianoPreviewSoftbox"
 scene.add_child(lamp)
 lamp.owner=scene
 lamp.position=bounds.get_center()+Vector3(4,3,1)
 lamp.look_at(bounds.get_center())
 lamp.light_energy=4
 lamp.spot_range=12
 lamp.spot_angle=50
 lamp.light_size=1
 lamp.shadow_enabled=true
 for n in piano.get_children():n.position-=Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
 var packed=PackedScene.new()
 packed.pack(piano)
 ResourceSaver.save(packed,"res://art/music_hall/piano.tscn")
 packed=PackedScene.new()
 packed.pack(scene)
 ResourceSaver.save(packed,"res://art/music_hall/music_hall.tscn")
 piano.free()
 quit()

extends SceneTree
func bounds(n:Node,t:Transform3D)->AABB:
 var b=AABB();var first=true
 if n is Node3D:t=t*n.transform
 if n is MeshInstance3D:b=t*n.get_aabb();first=false
 for c in n.get_children():
  var q=bounds(c,t)
  if q.size.length()>0:
   if first:b=q;first=false
   else:b=b.merge(q)
 return b
func _initialize():
 var s=load("res://art/armory/armory.tscn").instantiate()
 for n in s.get_node("RoyalDecorAndImportedWeapons").get_children():
  var b=bounds(n,Transform3D.IDENTITY)
  if b.size.y>3.4:print(n.name," ",b)
 s.free();quit()

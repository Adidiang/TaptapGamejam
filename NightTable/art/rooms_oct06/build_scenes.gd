extends SceneTree
const IDS=["storage","servants_dorm","queen_boss","study","kitchen","guest_room"]
func from_rows(a:Array)->Transform3D:
 return Transform3D(Basis(Vector3(a[0][0],a[1][0],a[2][0]),Vector3(a[0][1],a[1][1],a[2][1]),Vector3(a[0][2],a[1][2],a[2][2])),Vector3(a[0][3],a[1][3],a[2][3]))
func own_layout(n:Node,room:Node):
 for c in n.get_children():
  c.scene_file_path="";c.owner=room;own_layout(c,room)
func _initialize():
 for id in IDS:
  var path="res://art/rooms_oct06/"+id+"/"
  var meta=JSON.parse_string(FileAccess.get_file_as_string(path+"source_layout.json"))
  var room=Node3D.new();room.name=id.to_pascal_case();root.add_child(room)
  var layout=load(path+id+".glb").instantiate();layout.name="Layout";room.add_child(layout);layout.owner=room
  # Keep GLB as an external instance so source meshes stay replaceable.
  for cam in layout.find_children("*","Camera3D",true,false):cam.current=false
  var preview=Camera3D.new();preview.name="PreviewCamera";room.add_child(preview);preview.owner=room
  var selected=meta.cameras[0]
  for cam in meta.cameras:
   if cam.name==meta.active_camera:selected=cam
  preview.transform=from_rows(selected.transform);preview.fov=selected.fov;preview.near=maxf(selected.near,.01);preview.far=selected.far
  if selected.type=="ORTHO":preview.projection=Camera3D.PROJECTION_ORTHOGONAL;preview.size=selected.size
  preview.current=true
  var group=Node3D.new();group.name="AreaLightPreview";room.add_child(group);group.owner=room
  for src in meta.lights:
   if src.type!="AREA":continue
   var light=SpotLight3D.new();light.name=src.name;group.add_child(light);light.owner=room;light.transform=from_rows(src.transform)
   light.light_color=Color(src.color[0],src.color[1],src.color[2]);light.light_energy=clampf(src.energy/100.0,.1,8.0);light.light_size=.5;light.spot_range=30;light.spot_angle=80;light.spot_attenuation=.5;light.shadow_enabled=true
  var world=WorldEnvironment.new();world.name="PreviewEnvironment";room.add_child(world);world.owner=room
  var env=Environment.new();world.environment=env;env.background_mode=Environment.BG_COLOR;env.background_color=Color(.12,.13,.15)
  env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color(.85,.87,.92);env.ambient_light_energy=.5;env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.ssao_enabled=true
  room.set_meta("source_blend",meta.source)
  if id=="servants_dorm":
   for light in layout.find_children("*","DirectionalLight3D",true,false):light.light_energy=1.0;light.shadow_enabled=true
   layout.scene_file_path="";own_layout(layout,room)
  var packed=PackedScene.new();assert(packed.pack(room)==OK);assert(ResourceSaver.save(packed,path+id+".tscn")==OK)
  print("ROOM_SAVED ",id);room.free()
 quit()



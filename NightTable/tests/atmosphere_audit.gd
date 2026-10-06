extends SceneTree
func _initialize():call_deferred("capture_rooms")
func shot(view:CastleView,path:String):
 for f in 12:await process_frame
 await RenderingServer.frame_post_draw
 view.get_child(0).get_texture().get_image().save_png(path)
func capture_rooms():
 root.size=Vector2i(1600,900)
 var route=CastleGenerator.ROUTE
 var specs=[route.bedroom]+Array(route.events)+[route.battle]
 var folder="F:/gamejam/outputs/atmosphere_audit"
 DirAccess.make_dir_recursive_absolute(folder)
 var report={}
 for spec in specs:
  var key=spec.scene_path.get_file().get_basename().trim_suffix("_room")
  var state=CastleExploration.new()
  state.layout={"rooms":[],"rows":[[]],"stairs":[],"width":1,"floors":1,"spawn":0,"boss":-1}
  CastleGenerator._add_room(state.layout,0,0,"spawn",spec)
  state._enter(0)
  var view=CastleView.new()
  view.configure(state)
  root.add_child(view)
  view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  view.set_process(false);view.focused=false
  await process_frame
  var visual=view.room_visuals[0]
  view.camera.position=(visual.camera_left+visual.camera_right)*.5
  view.camera.rotation_degrees=Vector3(spec.camera_pitch,0,0)
  view.camera.fov=spec.camera_fov
  # Delayed resize snap must finish before restoring the exact midpoint.
  for f in 4:await process_frame
  view.camera.position=(visual.camera_left+visual.camera_right)*.5
  await shot(view,folder+"/"+key+"_current.png")
  var env=view.environment.environment
  var info={"name":spec.display_name,"camera":str(view.camera.position),"environment":{},"filter":{}}
  for prop in ["tonemap_mode","tonemap_exposure","ambient_light_color","ambient_light_energy","fog_enabled","fog_density","fog_light_color","fog_light_energy","volumetric_fog_enabled","volumetric_fog_density","glow_enabled","glow_intensity","glow_bloom","adjustment_enabled","adjustment_brightness","adjustment_contrast","adjustment_saturation"]:
   info.environment[prop]=str(env.get(prop))
  var mat=view.paper_rect.material as ShaderMaterial
  if mat:
   for uniform in mat.shader.get_shader_uniform_list():info.filter[uniform.name]=str(mat.get_shader_parameter(uniform.name))
  # A second game-view angle, without altering scene files.
  view.camera.position=visual.camera_right
  await shot(view,folder+"/"+key+"_right.png")
  view.camera.position=(visual.camera_left+visual.camera_right)*.5
  if key in ["bedroom","auditorium"]:
   view.paper_rect.hide()
   await shot(view,folder+"/"+key+"_no_filter.png")
   var fog=env.fog_enabled;var volume=env.volumetric_fog_enabled
   env.fog_enabled=false;env.volumetric_fog_enabled=false
   await shot(view,folder+"/"+key+"_no_filter_no_fog.png")
   env.fog_enabled=fog;env.volumetric_fog_enabled=volume
  report[key]=info
  print("CAPTURED ",key)
  view.queue_free()
  for f in 4:await process_frame
 var file=FileAccess.open(folder+"/settings.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"\t"));file.close()
 print("ATMOSPHERE_AUDIT_DONE")
 quit()

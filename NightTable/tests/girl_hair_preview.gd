extends SceneTree
func _initialize():call_deferred("render_preview")
func render_preview():
 root.size=Vector2i(640,640)
 var world=Node3D.new()
 root.add_child(world)
 var girl=load("res://art/characters/girl/girl.tscn").instantiate()
 world.add_child(girl)
 girl.set_process(false)
 girl.animation_player.callback_mode_process=2
 var env=WorldEnvironment.new()
 env.environment=Environment.new()
 env.environment.background_mode=Environment.BG_COLOR
 env.environment.background_color=Color(.13,.15,.18)
 env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color=Color(.8,.85,.95)
 env.environment.ambient_light_energy=.6
 world.add_child(env)
 var light=DirectionalLight3D.new()
 light.rotation_degrees=Vector3(-35,-40,0)
 light.light_energy=1.5
 world.add_child(light)
 var cam=Camera3D.new()
 world.add_child(cam)
 cam.position=Vector3(1.6,.95,2)
 cam.look_at(Vector3(0,.58,0))
 cam.projection=Camera3D.PROJECTION_ORTHOGONAL
 cam.size=1.65
 cam.current=true
 var label=Label.new()
 label.position=Vector2(24,24)
 label.add_theme_font_size_override("font_size",22)
 root.add_child(label)
 var folder="F:/gamejam/outputs/hair_gravity"
 DirAccess.make_dir_recursive_absolute(folder)
 for i in 90:
  var moving=i<40
  girl.update_locomotion(Vector2.DOWN if moving else Vector2.ZERO,.05)
  girl._process(.05)
  girl.animation_player.advance(.05)
  label.text="RUN" if moving else "STOP / SETTLE"
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(folder+"/%03d.png"%i)
 print("HAIR_PREVIEW_DONE")
 quit()

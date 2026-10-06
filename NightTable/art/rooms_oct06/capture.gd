extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1280,720);root.msaa_3d=Viewport.MSAA_4X
 var ids=OS.get_cmdline_user_args()
 if ids.is_empty():ids=PackedStringArray(["storage","servants_dorm","queen_boss","study","kitchen","guest_room"])
 for id in ids:
  var room=load("res://art/rooms_oct06/"+id+"/"+id+".tscn").instantiate();root.add_child(room);room.get_node("PreviewCamera").make_current()
  for i in 12:await process_frame
  await RenderingServer.frame_post_draw
  assert(root.get_texture().get_image().save_png("F:/gamejam/outputs/rooms_oct06/"+id+".png")==OK)
  print("CAPTURED ",id);room.queue_free();await process_frame;await process_frame
 quit()


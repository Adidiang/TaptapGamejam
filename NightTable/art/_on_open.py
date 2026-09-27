"""Blender 打开 whitebox.blend 时顺带做的几件小事。

用法（GUI 模式）：blender.exe art/whitebox.blend --python art/_on_open.py
- 保证有一台 SIDE_CAM 横板正交相机（没有就按场景包围盒现场建一台）
- 设为场景活动相机，并尽量把 3D 视口切过去（手动版：小键盘 0）
"""

import bpy
from mathutils import Vector

CAM_ORTHO_SCALE = 12.0     # 跟 Godot 侧的 CAM_SIZE 一致，单位米（人物 1.7 m 占画面 14%）
CAM_DISTANCE = 60.0        # 正交下不影响成像大小，只要远到不被裁剪


def _scene_bounds() -> tuple[Vector, Vector]:
    """所有带几何的物体的世界包围盒，返回 (min, max)。"""
    mins = []
    maxs = []
    for obj in bpy.context.scene.objects:
        if obj.type not in {"MESH", "CURVE", "SURFACE", "META"}:
            continue
        if not obj.data:
            continue
        for corner in obj.bound_box:
            world = obj.matrix_world @ Vector(corner)
            mins.append(world)
            maxs.append(world)
    if not mins:
        return Vector((0.0, 0.0, 0.0)), Vector((0.0, 0.0, 0.0))
    return (
        Vector((min(v.x for v in mins), min(v.y for v in mins), min(v.z for v in mins))),
        Vector((max(v.x for v in maxs), max(v.y for v in maxs), max(v.z for v in maxs))),
    )


def _make_side_cam() -> bpy.types.Object:
    """横板正视图：站在 -Y 侧看向 +Y。

    Blender 是 Z-up：Blender X = Godot X（房间排列方向 = 画面右方），
    Blender Z = Godot Y（高度 = 画面上方），Blender Y = Godot Z（进深）。
    Godot 的 1.1 m 矮墙那面在 Godot +Z，映射到 Blender 就是 -Y —— 相机必须站这边，
    站反了整栋楼会左右镜像。
    """
    low, high = _scene_bounds()
    width = max(high.x - low.x, 1.0)
    height = max(high.z - low.z, 1.0)
    depth = max(high.y - low.y, 1.0)

    data = bpy.data.cameras.new("SIDE_CAM")
    data.type = "ORTHO"
    # ortho_scale 是画面「高度」方向的世界尺寸；横向还要乘视口宽高比。
    # 取能一眼看全整栋楼的值（16:9 下约为 width / 1.78），不够就退回约定视野。
    data.ortho_scale = max(CAM_ORTHO_SCALE, width / 1.78, height) * 1.05
    data.clip_end = 1000.0
    obj = bpy.data.objects.new("SIDE_CAM", data)
    obj.location = (
        (low.x + high.x) * 0.5,
        low.y - CAM_DISTANCE - depth,
        (low.z + high.z) * 0.5,
    )
    obj.rotation_euler = Vector((0.0, 1.0, 0.0)).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.collection.objects.link(obj)
    return obj


def _view_camera() -> None:
    """把某个 3D 视口切到相机视角。启动脚本阶段 screen 还没就绪，靠 timer 延迟跑。"""
    try:
        for window in bpy.context.window_manager.windows:
            for area in window.screen.areas:
                if area.type != "VIEW_3D":
                    continue
                for region in area.regions:
                    if region.type != "WINDOW":
                        continue
                    with bpy.context.temp_override(window=window, area=area, region=region):
                        bpy.ops.view3d.view_camera()
                    print("[godot-link] 3D 视口已切到 SIDE_CAM")
                    return
        print("[godot-link] 没找到 3D 视口，手动按小键盘 0 切相机视角")
    except Exception as exc:  # noqa: BLE001 打开了就行，别为视角报错
        print("[godot-link] 自动切视角失败（手动按小键盘 0）：%s" % exc)


def main() -> None:
    cam = bpy.data.objects.get("SIDE_CAM")
    if cam is None:
        cam = _make_side_cam()
        print("[godot-link] 已新建横板正交相机 SIDE_CAM")
    bpy.context.scene.camera = cam
    print("[godot-link] 活动相机 = SIDE_CAM（正交 %.1f m，横板正视图）" % cam.data.ortho_scale)
    bpy.app.timers.register(_view_camera, first_interval=2.0)


main()

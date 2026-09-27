"""把 Level 1 白盒导进 Blender。

用法 A —— 导进「现在已经开着的那台 Blender」（推荐）：
    Blender 顶栏切到 Scripting → 打开本文件 → Run Script。
    白盒会直接出现在当前场景里，不用新建文件、不用保存当前工程。

用法 B —— 命令行生成一个 .blend 文件（给 File > Append / Open 用）：
    blender --background --factory-startup --python 本文件 -- 输出.blend

轴向说明：Godot 是 Y 向上，Blender 是 Z 向上。
glTF 导入器会先给根节点套一个 -90° 的 X 旋转，所以视觉上已经是站着的；
本脚本再把这个旋转烘进几何（bake），根节点归零，
于是「Godot 的 X = Blender 的 X，Godot 的 Y(高度) = Blender 的 Z，Godot 的 Z(进深) = Blender 的 Y」，
在 Blender 里量到的米数跟 Godot 完全一致。
"""

import math
import os
import sys

import bpy
from mathutils import Matrix, Vector

GLB = os.path.join(os.path.dirname(os.path.abspath(__file__)), "level1_whitebox.glb")
COLLECTION_NAME = "Level1Whitebox"

# 要不要顺手建一台和 Godot 里一样的横板正交相机，并设为场景活动相机。
# 参数逐个对齐 level1_whitebox.gd 的 CAM_SIZE / CAM_PITCH_DEG / CAM_LIFT。
ADD_SIDE_CAMERA = True
CAM_SIZE = 12.0            # 画面高度（米）。配合 sensor_fit=VERTICAL，人物 1.7 m 占 14% 画面（对齐参考图）
CAM_PITCH_DEG = 18.2       # 下俯角 —— 不俯视的话地板只会是一条线
CAM_HEIGHT = 12.91         # 相机中心离地面多高（= Godot 的 _cam_lift()）
CAM_DISTANCE = 25.0        # 水平距离，正交下不影响成像大小
CAM_X = 0.0                # 对准哪一段（0 = 一楼大堂）


def import_glb(path: str):
    """导入 glb，返回这次新加进来的顶层物体。"""
    before = set(bpy.data.objects)
    if hasattr(bpy.ops.import_scene, "gltf"):
        bpy.ops.import_scene.gltf(filepath=path)
    else:  # 新版 Blender 改过操作符名字，两个都试一遍
        bpy.ops.wm.gltf_import(filepath=path)
    added = [o for o in bpy.data.objects if o not in before]
    return [o for o in added if o.parent is None]


def bake(root) -> None:
    """把根节点的世界旋转烘进整棵子树，并让根节点自身变换归零。

    这样物体在 Blender 里是「干净」的：位置/旋转不带着 glTF 的坐标系转换，
    直接改坐标就行，也不会出现「一旋转父级整栋楼跟着翻」的情况。
    """
    def walk(obj, out, depth=0):
        out.append((depth, obj))
        for child in obj.children:
            walk(child, out, depth + 1)

    ordered = []
    for r in root:
        walk(r, ordered)
    # 从浅到深：先定父级的世界矩阵，子级的局部矩阵才算得对。
    ordered.sort(key=lambda pair: pair[0])

    worlds = {obj: obj.matrix_world.copy() for _, obj in ordered}
    rotation = {obj: obj.matrix_basis.copy() for _, obj in ordered if obj.parent is None}

    for _, obj in ordered:
        obj.matrix_parent_inverse = Matrix()
    for _, obj in ordered:
        if obj.parent is None:
            obj.matrix_basis = Matrix()

    bpy.context.view_layer.update()

    for _, obj in ordered:
        parent = obj.parent
        if parent is None:
            obj.matrix_world = rotation[obj] @ worlds[obj]
        else:
            obj.matrix_world = rotation_root_of(parent, rotation) @ worlds[obj]


def rotation_root_of(obj, rotation) -> Matrix:
    """往上找到所属那棵树的根，拿它的原始旋转。"""
    node = obj
    while node.parent is not None:
        node = node.parent
    return rotation.get(node, Matrix())


def report(roots) -> None:
    bpy.context.view_layer.update()
    min_x = min_y = min_z = 1e9
    max_x = max_y = max_z = -1e9
    count = 0
    for r in roots:
        for obj in [r] + list(r.children_recursive):
            if obj.type != "MESH":
                continue
            count += 1
            for corner in obj.bound_box:
                world = obj.matrix_world @ Vector(corner)
                min_x = min(min_x, world.x); max_x = max(max_x, world.x)
                min_y = min(min_y, world.y); max_y = max(max_y, world.y)
                min_z = min(min_z, world.z); max_z = max(max_z, world.z)
    # 顺带确认朝向：相机侧（-Y，Godot 的 +Z）应该只有 1.1 m 矮墙，
    # 整排高墙应该在背面。搞反了的话整栋楼是背对相机的。
    # 0 = 这一侧什么都没有；用 -1e9 当哨兵会在报告里打出 -1000000000，很难读
    front_top = 0.0
    back_top = 0.0
    for r in roots:
        for obj in [r] + list(r.children_recursive):
            if obj.type != "MESH":
                continue
            center = obj.matrix_world @ Vector((0.0, 0.0, 0.0))
            top = max((obj.matrix_world @ Vector(c)).z for c in obj.bound_box)
            if center.y < -4.0:
                front_top = max(front_top, top)
            elif center.y > 4.0:
                back_top = max(back_top, top)

    print("[whitebox] mesh 数量: %d" % count)
    print("[whitebox] 包围盒 X(宽) %.1f m  Y(进深) %.1f m  Z(高) %.1f m"
          % (max_x - min_x, max_y - min_y, max_z - min_z))
    # 相机侧（Blender -Y = Godot 前侧）按设计是剖开的：不给前墙（RAIL_H=0），
    # 所以这里应该量不到东西。要是蹦出 ~13 甚至 ~26，说明前后搞反了、相机站到了背面。
    print("[whitebox] 相机侧最高 %.1f m / 背面最高 %.1f m（相机侧应≈0，即前侧无遮挡）"
          % (front_top, back_top))
    print("[whitebox] 期望：X≈152 宽、Y≈10 进深、Z≈26 高（两层各 7.5 m + Boss 房 11 m）")


def group(roots) -> None:
    """塞进一个同名集合，方便整体隐藏/选中。"""
    collection = bpy.data.collections.get(COLLECTION_NAME)
    if collection is None:
        collection = bpy.data.collections.new(COLLECTION_NAME)
        bpy.context.scene.collection.children.link(collection)
    # 注意：必须把**每一个**物体都 link 进集合，不能只 link 根。
    # 只 link 根的话，集合里名义上只有 1 个物体，之后 File > Append 这个集合
    # 只会带进来根节点那一个 —— 169 个子级全丢。
    for r in roots:
        for obj in [r] + list(r.children_recursive):
            for existing in list(obj.users_collection):
                existing.objects.unlink(obj)
            collection.objects.link(obj)


def side_camera() -> None:
    """一台和 Godot 里同款的横板正交相机。

    轴向：Godot (x, y, z) 进 Blender 是绕 X 转 +90°，变成 (x, -z, y)，
    所以 Godot 的前侧（+Z，也就是横板相机那一侧）落在 Blender 的 -Y。
    相机要站在 -Y 侧往 +Y 看，画面右方才是 +X（房间的排列方向，跟设计图一致）、
    上方才是 +Z（高度）。站反了整栋楼会左右镜像。
    导入完按小键盘 0 就能进这个视角。

    俯角方向和 Godot 一样：Godot 里相机绕 X 转 -9.5° 是低头，
    因为 X 轴在两个引擎里是同一个方向、都是右手系，所以 Blender 里也绕 X 转 -9.5°。
    实测这里写成「朝向 = (0, cosθ, -sinθ)」再用 -Z 去 track 最省事。
    """
    scene = bpy.context.scene
    data = bpy.data.cameras.new("SIDE_CAM")
    data.type = "ORTHO"
    data.sensor_fit = "VERTICAL"     # 让 ortho_scale 直接就是画面「高度」，不被宽高比带跑
    data.ortho_scale = CAM_SIZE
    data.clip_start = 0.1
    data.clip_end = 1000.0
    obj = bpy.data.objects.new("SIDE_CAM", data)
    obj.location = (CAM_X, -CAM_DISTANCE, CAM_HEIGHT)
    pitch = math.radians(CAM_PITCH_DEG)
    look = Vector((0.0, math.cos(pitch), -math.sin(pitch)))
    obj.rotation_euler = look.to_track_quat("-Z", "Y").to_euler()
    scene.collection.objects.link(obj)
    scene.camera = obj
    bpy.context.view_layer.update()
    m = obj.matrix_world.to_3x3()
    right = m @ Vector((1.0, 0.0, 0.0))
    up = m @ Vector((0.0, 1.0, 0.0))
    fwd = m @ Vector((0.0, 0.0, -1.0))
    print("[whitebox] 相机 右方=(%.0f,%.0f,%.0f) 上方=(%.0f,%.0f,%.0f) 朝向=(%.2f,%.2f,%.2f) 期望 (+X, +Z, 略微朝下)"
          % (right.x, right.y, right.z, up.x, up.y, up.z, fwd.x, fwd.y, fwd.z))
    print("[whitebox] 取景 高 %.1f m × 宽 %.1f m（16:9），下俯 %.1f°"
          % (CAM_SIZE, CAM_SIZE * 16.0 / 9.0, CAM_PITCH_DEG))


def main() -> None:
    if not os.path.exists(GLB):
        print("[whitebox] 找不到 %s，先在 Godot 里跑一次导出" % GLB)
        return
    roots = import_glb(GLB)
    if not roots:
        print("[whitebox] 导入失败：没拿到任何物体")
        return
    bake(roots)
    group(roots)
    report(roots)
    if ADD_SIDE_CAMERA:
        side_camera()

    if bpy.app.background:
        out = None
        if "--" in sys.argv:
            tail = sys.argv[sys.argv.index("--") + 1:]
            if tail:
                out = tail[0]
        if out:
            bpy.ops.wm.save_as_mainfile(filepath=out)
            print("[whitebox] 已保存 .blend: %s" % out)
    else:
        print("[whitebox] 已导入当前场景，集合名：%s" % COLLECTION_NAME)


main()

"""Blender ⇄ Godot 联动（一个文件，两种用法）

用法 A · 装成插件（推荐，一次装好永久生效）
    Blender: Edit > Preferences > Add-ons > Install from Disk → 选本文件 → 勾选启用。
    启用后：每次在 Blender 里 Ctrl+S，自动把当前文件导出成 glTF 到 GODOT_DIR，
    Godot 检测到文件变化会自动重新导入 —— 切回 Godot 就是新的。
    不想自动的话，在插件首选项里关掉 "Auto Export On Save"，改用
    F3 搜 "Godot: Export Now" 手动导。

用法 B · 命令行导一次（不装插件也能用）
    blender --background --factory-startup "你的.blend" --python 本文件 -- "输出.glb"

## 导出范围（重要！）
不是整个场景都导出 —— 只有「导出集合」里的对象会进 glb：
    - 插件首选项里配置集合名（逗号分隔），默认 "Level1Whitebox"
    - 集合为空/找不到时导出整个场景（并打警告）
这样你可以把 AI 模型、参考图之类的随便丢进 Blender 当参考或继续编辑，
保存时它们**不会**涌进 Godot。想导出某个 AI 模型时，把它挪进导出集合即可，
或者给它单独存一个 .blend 文件（导出的 glb 跟 .blend 同名）。

相机一律不导出 —— Godot 场景里自己建相机管取景。
"""

import os

import bpy

bl_info = {
    "name": "Godot Link (auto export glTF)",
    "blender": (4, 0, 0),
    "category": "Import-Export",
    "author": "NightTable",
    "version": (1, 1, 0),
    "description": "保存时自动导出 glTF 到 Godot 项目目录（按集合过滤）",
}

# Godot 项目里放美术的目录。改成你自己的路径即可。
GODOT_DIR = "C:/Users/12579/Documents/TaptapGamejam/NightTable/art"
# 默认导出的集合名（插件首选项里可改）
DEFAULT_EXPORT_COLLECTIONS = "Level1Whitebox"


def export_glb(out_path: str, export_collections: str = "") -> bool:
    """导出为 glTF 二进制。+Y up、应用修改器，跟 Godot 的坐标系一致。

    export_collections: 逗号分隔的集合名。非空时只导出这些集合里的对象
    （含子孙）；为空或集合不存在/为空时导出整个场景。相机永远不导出
    （通过 selection 实现：先选中要导的对象，再 use_selection=True）。
    """
    folder = os.path.dirname(out_path)
    if folder:
        os.makedirs(folder, exist_ok=True)

    # 决定导出哪些对象
    export_names = [s.strip() for s in export_collections.split(",") if s.strip()]
    wanted: set = set()
    filter_active = False
    if export_names:
        missing = []
        for coll_name in export_names:
            coll = bpy.data.collections.get(coll_name)
            if coll is None:
                missing.append(coll_name)
                continue
            for obj in coll.all_objects:
                if obj.type != 'CAMERA':
                    wanted.add(obj.name)
                    stack = list(obj.children)  # 递归收子孙（empty 层级下的模型）
                    while stack:
                        child = stack.pop()
                        if child.type != 'CAMERA':
                            wanted.add(child.name)
                            stack.extend(child.children)
        if missing:
            print("[godot-link] 警告: 找不到导出集合 %s（检查名字拼写），改导整个场景" % missing)
        elif wanted:
            filter_active = True
        else:
            print("[godot-link] 警告: 导出集合 %s 里没有对象，改导整个场景" % export_names)

    # 选中要导出的对象（相机永不选）
    bpy.ops.object.select_all(action='DESELECT')
    if filter_active:
        for name in wanted:
            obj = bpy.data.objects.get(name)
            if obj:
                obj.select_set(True)
        print("[godot-link] 按集合过滤: 导出 %d / %d 个对象（集合 %s）"
              % (len(wanted), len(bpy.data.objects), export_names))
    else:
        for obj in bpy.context.scene.objects:
            if obj.type != 'CAMERA':
                obj.select_set(True)
        print("[godot-link] 导出整个场景（排除相机）")

    kwargs = {
        "filepath": out_path,
        "export_format": "GLB",
        "export_yup": True,
        "export_apply": True,
        "use_selection": True,
    }
    try:
        bpy.ops.export_scene.gltf(**kwargs)
    except TypeError:
        # 不同 Blender 版本的导出器参数名会有出入，退化到最小参数集再试一次
        bpy.ops.export_scene.gltf(filepath=out_path, export_format="GLB")
    ok = os.path.exists(out_path)
    print("[godot-link] %s -> %s (%.1f KB)"
          % ("导出成功" if ok else "导出失败", out_path,
             os.path.getsize(out_path) / 1024.0 if ok else 0.0))
    return ok


def target_path() -> str:
    """Godot 里的目标文件名：跟着 .blend 的文件名走。"""
    current = bpy.data.filepath
    name = os.path.splitext(os.path.basename(current))[0] if current else "untitled"
    return os.path.join(GODOT_DIR, name + ".glb")


# ---------------------------------------------------------------- 插件本体

class GODOT_OT_export_now(bpy.types.Operator):
    bl_idname = "godot.export_now"
    bl_label = "Godot: Export Now"
    bl_description = "把当前场景导出成 glTF 到 Godot 目录"

    def execute(self, context):
        if not bpy.data.filepath:
            self.report({"WARNING"}, "先保存一次 .blend，我才能知道该叫什么名字")
            return {"CANCELLED"}
        colls = DEFAULT_EXPORT_COLLECTIONS
        prefs = _prefs()
        if prefs:
            colls = prefs.export_collections
        export_glb(target_path(), colls)
        return {"FINISHED"}


class GodotLinkPreferences(bpy.types.AddonPreferences):
    bl_idname = __name__

    godot_dir: bpy.props.StringProperty(
        name="Godot 目录",
        description="导出的 glTF 放到哪个目录（要在 Godot 项目里）",
        subtype="DIR_PATH",
        default=GODOT_DIR,
    )
    auto_export: bpy.props.BoolProperty(
        name="保存时自动导出",
        description="Ctrl+S 之后自动导一次；关掉就用 F3 搜 Godot: Export Now",
        default=True,
    )
    export_collections: bpy.props.StringProperty(
        name="导出集合",
        description="只导出这些集合里的对象（逗号分隔）。留空 = 导出整个场景。"
                    "AI 模型、参考物放别的集合就不会被导出",
        default=DEFAULT_EXPORT_COLLECTIONS,
    )

    def draw(self, context):
        self.layout.prop(self, "godot_dir")
        self.layout.prop(self, "auto_export")
        self.layout.prop(self, "export_collections")
        self.layout.label(text="导出的文件名 = 当前 .blend 的文件名；相机永不导出")


def _prefs():
    try:
        return bpy.context.preferences.addons[__name__].preferences
    except Exception:
        return None


@bpy.app.handlers.persistent
def on_save_post(_dummy) -> None:
    """保存后自动导出。整体包在 try 里：这个 handler 在
    save_userpref / 无文件（_RestrictData）等场景也会被触发，
    任何异常都不能往外抛，否则会打断 Blender 自己的保存流程。

    必须加 @persistent：Blender 每次加载 .blend 都会清空非持久化的
    handler，不加的话「打开白盒文件」这个动作就把回调抹掉了，
    导致 Ctrl+S 永远不导出。"""
    global GODOT_DIR
    try:
        colls = DEFAULT_EXPORT_COLLECTIONS
        try:
            prefs = bpy.context.preferences.addons[__name__].preferences
            GODOT_DIR = prefs.godot_dir
            colls = prefs.export_collections
            if not prefs.auto_export:
                return
        except Exception:
            pass
        # 注意：某些上下文（如 save_userpref）里取 filepath 会抛
        # AttributeError: '_RestrictData' object has no attribute 'filepath'
        try:
            path = bpy.data.filepath
        except Exception:
            path = ""
        if not path:
            return
        export_glb(target_path(), colls)
    except Exception as exc:
        print("[godot-link] 自动导出跳过：%s" % exc)


classes = [GODOT_OT_export_now, GodotLinkPreferences]


def register():
    # 幂等：首次启用若中途崩过，类会残留在 Blender 里，
    # 再次 register_class 会抛 "already registered as a subclass"，
    # 结果是 save_post 回调永远挂不上（保存不导出）。
    # 所以逐个 try，已注册的跳过。
    for cls in classes:
        try:
            bpy.utils.register_class(cls)
        except ValueError as exc:
            print("[godot-link] 跳过已注册的类 %s：%s" % (cls.__name__, exc))
    if on_save_post not in bpy.app.handlers.save_post:
        bpy.app.handlers.save_post.append(on_save_post)


def unregister():
    if on_save_post in bpy.app.handlers.save_post:
        bpy.app.handlers.save_post.remove(on_save_post)
    for cls in reversed(classes):
        try:
            bpy.utils.unregister_class(cls)
        except Exception as exc:
            print("[godot-link] 注销类 %s 时跳过：%s" % (cls.__name__, exc))


# ---------------------------------------------------------------- 命令行模式

# 命令行模式：blender --background --factory-startup 文件.blend --python 本文件 -- 输出.glb [导出集合]
# 第二个可选参数 = 导出集合名（逗号分隔），不给则用 DEFAULT_EXPORT_COLLECTIONS。
#
# 判据必须是 __name__ == "__main__"（= 本文件被 --python 直接执行）。
# 不能只用 bpy.app.background —— 插件模式下 Blender 也是后台进程，
# addon_enable 加载本模块时若走这段，会拿受限的 bpy.data 去导出而崩溃，
# 导致插件根本启用不了。
if __name__ == "__main__" and bpy.app.background:
    import sys

    out = None
    colls = DEFAULT_EXPORT_COLLECTIONS
    if "--" in sys.argv:
        tail = sys.argv[sys.argv.index("--") + 1:]
        if tail:
            out = tail[0]
        if len(tail) > 1:
            colls = tail[1]
    export_glb(out or target_path(), colls)

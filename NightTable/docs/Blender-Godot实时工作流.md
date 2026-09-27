# Blender ⇄ Godot 实时工作流

目标：在 Blender 里建/改 → 保存 → 切到 Godot，3D 视口里就是新的。
参考：BV1XKNAePEnX（Godot 的 `.blend` 导入本质上是「先调 Blender 转成 glTF，再走 glTF 导入」）。

## 已经配好的东西

| 项 | 值 |
| --- | --- |
| Godot 的 Blender 路径 | `filesystem/import/blender/blender_path` = `F:/SteamLibrary/steamapps/common/Blender/blender.exe` |
| Godot 的外部 3D 编辑器 | 同一个 exe —— 在 Godot 里双击 `.blend` 会直接用 Blender 打开接着改 |
| 美术目录 | `NightTable/art/` —— Godot 自动导入里面的 `.glb` / `.blend` |
| 预览场景 | `scenes/art_preview.tscn`（模型 + 主光 + 补光 + 横板正交相机，引用 `art/whitebox.blend`） |
| Blender 端插件 | `art/blender_godot_link.py`（保底用，`.blend` 直连正常时不需要装） |
| 桌面启动器 | `在Blender里打开白盒.bat`（开 Blender + 顺带在资源管理器里定位文件） |

> **改了编辑器设置必须重启 Godot 才生效。** Godot 退出时会把自己内存里的设置写回去，
> 不先关掉再开的话，上面那两行会被冲掉。

## 链路 A · `.blend` 直接放项目里（双向，视频那套）

1. Blender 里 `File > Save As` 到 `NightTable\art\whitebox.blend`（只做一次）。
   文件必须在项目目录里 —— Godot 只导入 `res://` 内的东西，`F:\blender\` 这种外部路径它看不见。
2. Godot 会自动把它转成 glTF 再导入，双击就能看。
3. 之后：Blender 里改 → `Ctrl+S` → 切回 Godot，3D 视口自动更新。
4. 反向：Godot 的 FileSystem 里双击 `.blend` → 直接用 Blender 打开接着改。

**已验证可用**：`.godot/imported/` 里生成了 `whitebox.blend-*.scn` + 中间 glTF，
说明 Godot 确实调起了 Blender 5.1.2 完成了转换。另用探针脚本实测
`ResourceLoader.load("res://art/whitebox.blend")` → 171 个 mesh，
包围盒 `x ±76`（152 m 宽）/ `y -0.2..17.5`（三层高）/ `z ±5`（10 m 进深），
跟 Blender 里的数字完全对得上。

> 注：Godot 无头模式会拒绝「配置」Blender 路径（`Cannot configure blender path in
> headless mode`），但已经写进 `editor_settings` 的路径它是会拿来用的。所以这条链路
> 现在只是「有证据表明通了」，你在编辑器里双击场景亲眼确认一次才算数。
> 真报错就走链路 B，效果一样。

## 链路 B · Blender 保存自动导出 glTF（保底，也更可控）

1. Blender：`Edit > Preferences > Add-ons > Install from Disk` →
   选 `NightTable\art\blender_godot_link.py` → 勾选启用。
2. 之后每次 `Ctrl+S`，自动导出 `art\<同名>.glb`，Godot 自动重导入。
3. 不想自动：插件首选项里关掉 `Auto Export On Save`，改用 `F3` 搜 `Godot: Export Now` 手动导。
4. 临时导一次、不装插件：

   ```bat
   blender --background --factory-startup "F:\blender\whitebox.blend" ^
           --python "C:\Users\12579\Documents\TaptapGamejam\NightTable\art\blender_godot_link.py" ^
           -- "C:\Users\12579\Documents\TaptapGamejam\NightTable\art\whitebox.glb"
   ```

## 在 Godot 3D 视口里看

- 双击 `scenes/art_preview.tscn` → 切顶部 **3D**，模型就在视口里（已配好灯光，不会全黑）
- 按 **F6** 运行这个场景：用的是场景里的透视相机（fov 35°、俯角 12°），
  参数跟 `level1_whitebox.gd` 的跟随相机一致 —— 所见即游戏开局画面
- `art_preview.tscn` 引用的是 **`art/whitebox.glb`**（不是 .blend），
  走链路 B 的过滤导出 —— .blend 里塞了什么参考物都不会漏进来

模型没出来时的三步排查：

1. FileSystem 面板右键 `art` → **Reimport**
2. Godot 窗口要在前台 —— 不在前台时它不一定扫描文件变化
3. 看编辑器底部 Output 面板有没有导入报错（`.blend` 的话就是链路 A 失败了，改走链路 B）

## 导出范围：集合过滤（2026-09-27 加入，AI 模型工作流的关键）

**只有 `Level1Whitebox` 集合里的对象会被导出**（插件首选项可改），其余一律不出 glb：

- AI 模型（Tripo 生成物等）、参考物 → 随便丢进 `AIModels-noexport` 集合，
  Blender 里继续编辑，保存时**不会**涌进 Godot
- 想导出某个 AI 模型：把它挪进 `Level1Whitebox` 集合，或给它单独存一个
  `.blend`（导出的 glb 跟 .blend 同名，Godot 里单独引用）
- 相机永远不导出（Godot 场景里自己建相机）
- `.blend` 被名字以 `-noexport` 结尾的集合装着的对象，Godot 的 .blend 导入也会跳过（双保险）

## 坐标与单位

- 1 Blender 单位 = 1 米 = 1 Godot 单位，不用缩放
- Godot 是 Y-up，Blender 是 Z-up。这个白盒里：
  **Godot 的 +Z（前侧矮墙那面）= Blender 的 -Y**；
  Godot 的相机站 +Z 侧，Blender 里对应站 -Y 侧，站反了整栋楼左右镜像
- 导出一律 `+Y up` + 应用修改器，Godot 里不会出现躺倒的模型

## 现在的状态（2026-09-27 同步过一轮）

- `art/whitebox.blend` = 最新白盒（层高 10 m、透视相机时代，195 物体）
  **+ `AIModels-noexport` 集合（Tripo 模型等 9 个物体，不导出）**
- `art/whitebox.glb` = 只含白盒集合的导出（169 mesh / 325 KB），
  `art_preview.tscn` 引用它
- 同步白盒到 Blender 的命令（Godot 导出 → Blender 替换）：
  Godot 侧 `export_whitebox_gltf.gd` 出 glb → Blender 脚本删旧
  `Level1Whitebox` 集合 → import glb → **全部对象 link 进集合**（只 link
  根节点的话，无集合的子对象保存时会丢！）→ 保存

所以**直接 Blender 里 `File > Open` → `NightTable\art\whitebox.blend`，就在这份上继续做**。
`.blend` 必须在 Godot 项目里才能被自动导入，`F:\blender\` 那种外部目录 Godot 看不见。

想把白盒放进别的文件也行：

- `File > Append` → 选 `exports\level1_whitebox.blend` → `Collection` → `Level1Whitebox`
- 或者跑 `exports\import_into_blender.py`（会顺带建好 `SIDE_CAM` 横板相机）

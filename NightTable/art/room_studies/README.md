# 可编辑的房间美术

## 手绘渲染试版

纸本质感第二轮：texture_softness 调至 1.35，screen_softness 为 0，降低距离雾与泛光，恢复边缘和材质清晰度。材质加入固定于表面的细纸齿、干颜料变化；屏幕纸纹改为多尺度不规则纤维（paper_grain=0.045），并对现有明暗边界加入轻微墨线强调。未调整物件摆放或相机。这仍是原素材的风格化渲染，原贴图中的雕刻和木纹图案仍然保留。

绘本质感这一轮使用同一份 profile 的 Storybook surface 分组：storybook_strength 控制颜料色块、笔触与暖亮部／紫褐暗部调色的整体强度，paper_grain 控制细微纸纹。笔触以世界坐标固定在物体表面，纸纹保持静止。降低了空间雾、漂移雾和全屏柔化，以保留轮廓与明暗层次；房间摆放、相机和角色比例没有调整。修改前的参数备份为 `art/rendering/before_storybook.tres`，对比截图为 `captures/room_studies/before_storybook_event.png`。卡牌局内改用独立的 `art/duel/duel_profile.tres`，避免地图调色影响局内画面。

游戏与 F6 预览使用 `art/rendering/painterly_profile.tres`。在 Godot 检查器中调整 texture_softness（越大越省略纹理细节）、color_steps（明度色阶）、saturation、ambient_energy、key_energy、candle_energy_scale。修改后重新运行。enabled=false 可关闭这层风格处理，原始网格、材质和贴图没有被覆盖。

当前采用柔化的贴图采样、明度分组、少量大尺度颜料变化、无镜面高光和无凹凸法线的材质，并以暖烛光与偏冷环境光构成明暗。PNG 导入设置开启 mipmaps，供柔化采样使用。美术着色只覆盖实例的 surface material；小地图与 UI 保持原样。独立场景的编辑器静态预览仍可能显示原材质，按 F6 查看实际效果。

修改前对比图保存在 `captures/room_studies/before_painterly_shop.png` 和 `before_painterly_event.png`，最新效果为 `in_game_*.png`。

梦境氛围参数也在同一份 profile 的 Dream atmosphere 分组：mist_density 控制空间雾浓度，mist_color 控制雾色，glow_strength 控制柔光，screen_softness 控制轻微画面柔化，drifting_mist 控制底部缓慢漂移的薄雾。采用 Compatibility 可运行的普通距离雾、灯旁径向光晕和主 SubViewport 的柔光材质，没有切换渲染器。屏幕处理只作用于主房间纹理，UI 和小地图不参与；F6 单房间预览包含距离雾及灯旁光晕，完整屏幕柔光需在游戏中查看。修改前的无雾版本参考 `before_dream_event.png`。

这三个场景已通过 room_catalog.tres 接入游戏。打开 NightTable 项目后，在 Godot 中打开对应 .tscn，按 F6 可单独预览；保存后重新运行游戏即可看到修改。

- battle_room.tscn：两张圆桌、一张长桌、桌椅、石地板、吊灯。
- event_room.tscn：书架、旧书、陈列宝箱、烛台、绿色地毯。
- shop_room.tscn：雕花吧台、三个凳子、瓶架、酒桶与货箱。

场景内 Architecture、Furniture、SetDressing 分别存放建筑、家具和装饰/局部灯光。所有物件都是已保存的原生节点，名称已整理为素材名称加序号，可直接编辑，不要重新运行搭建脚本。改桌椅位置、增减物品、调整局部灯光，无需修改地图代码。

room_catalog.tres 是房型映射入口。在 Godot 检查器里可替换 battle_room、event_room、shop_room，以及共享的 doorway、ladder 场景。出生房和 Boss 房当前复用战斗房；将新场景填入 spawn_room 或 boss_room 即可分别替换。新房间建议复制现有模板，保留根节点脚本和接口节点。

PreviewRig 内的相机、环境和方向光只供 F6 预览；游戏实例化时移除这些预览节点，使用 CastleView 的统一环境和镜头。SetDressing 的局部灯光会保留。单房间主视图只显示当前房间美术，小地图继续显示已探索房间和通道，不加载详细模型。

游戏主镜头采用 15° 俯角和近距离满屏构图，在门口小幅横向跟随以保持角色可见；角色显示模型缩放为 0.52，逻辑移动坐标与小地图标记不变。镜头和角色比例由 scripts/castle_view.gd 的 ROOM_CAMERA_PITCH、PLAYER_VISUAL_SCALE 与 _update_camera 管理。F6 的独立样板预览仍保留较远镜头，方便检查完整房间。

房间占地为 10 × 7，地面顶面 y=0，后墙 z=-3.5，前方 z=3.5，墙高约 4。根节点 gameplay_offset 默认 (0,0,1.6)，把本地门口 z=0.7 对齐游戏行走路线 z=2.3。请给本地 z≈0.7 的横向路线和 x=±2.5 的梯子交互区留空；现有角色移动按逻辑坐标限制，不会被家具碰撞阻挡。

FutureGameplayAnchors/LeftDoor、RightDoor 是运行时门位置接口。它们应保持 x=±5、z=0.7；移动门口需要同时调整玩法通道，不能仅改美术。Interaction、Spawn 仍是参考标记，当前玩法不读取它们。Architecture/LeftDoorPreview、RightDoorPreview 为静态预览门，运行时由 doorway.tscn 替代；没有相邻房间的一侧使用 SealedWall，正常通道使用 Opening/Hinge，并由原有门锁状态控制开关。doorway.tscn 的这三个节点名称需保留。梯子使用 ladder.tscn，由生成器决定是否出现，不需要手工加入每间房。

素材来自用户提供的 scence_02。tavern_library/tavern_parts.gltf 将原素材的网格整理为单件库，保留原始二进制网格数据与共享贴图；meshes 中是 Godot 网格资源。未更改原始素材目录。

截图位于 ../../captures/room_studies/，由 Godot Compatibility 渲染器实际渲染。in_game_battle.png、in_game_event.png、in_game_shop.png 为接入后的游戏画面。

art/tools/build_room_studies.gd 和 prepare_room_templates.gd 为初次搭建/迁移工具，不属于日常编辑流程，已加覆盖保护。capture_room_studies.gd 用于独立场景截图；capture_integrated_rooms.gd 用于实际地图截图，运行需带 -- --smoke 以禁用玩家存档写入。

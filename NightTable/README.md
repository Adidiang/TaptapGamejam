# 余夜 / Night Table

用 Godot 打开 project.godot，按 F5 运行。桌面默认 Forward+；WASD / 方向键四向移动，F 交互，Tab 切换小地图视图。

## 当前编辑入口

- 新卧室：art/bedroom_v2/bedroom.tscn，F6 可独立预览。家具可单独调整。
- 旧版卧室效果参考：art/received_bedroom/bedroom.tscn，完整保留。
- 房间路线、门与碰撞：art/exploration/route.tres、bedroom_definition.tres，说明见 [房间实现](art/exploration/README.md)。
- 卧室镜头范围：FurnitureAndArchitecture 下的摄像机2为左端，摄像机为右端；游戏读取这两个节点的位置。
- 地图纸面滤镜：art/exploration/room_paper_filter.tres。
- 牌局美术：art/duel/；牌局逻辑：scripts/。
- 测试：tests/smoke.gd；镜头专项检查：art/exploration/check_camera_motion.gd。

## 目录整理

2026-10-04 将旧酒馆房间预览、早期白盒与卧室样例、旧截图、一次性重建脚本、已合并进场景的家具 GLB 中间文件移出工程。当前卧室和牌桌仍引用的酒馆书堆、桌椅、烛台等共享资源保留。

归档：../archive/cleanup_2026-10-04/legacy_project_files.zip。清单 manifest.json 包含原路径与 SHA256。需要恢复时按清单选择文件，将压缩包内的路径解压到 F:/gamejam；先确认不要覆盖后续修改。

原始 Blender 素材及外部素材库保留。运行中的 Godot 导入缓存未手动删除；.godot 为自动生成目录，不纳入版本控制。截图与历史备份放在工程外的 ../outputs/ 和 ../archive/，避免参与资源导入。

历次玩法与过期编辑入口见 [历史项目说明](docs/历史项目说明.md)，其中的旧场景路径可能已转入归档。

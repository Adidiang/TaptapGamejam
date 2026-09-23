# 余夜 / Night Table · 0.2

Godot 4.7 的 21 点肉鸽可玩原型。所有画面为程序占位美术。

## 启动

双击 `启动游戏.cmd`。编辑时用旁边的 Godot 导入 `project.godot`，按 F5 运行。使用 GDScript，无需安装额外 CLI 或 .NET SDK。

## 当前内容

- 三幕分支地图、牌桌、事件、休息、商店与三个不同规则的 Boss。
- 独立牌库、明暗牌、要牌/停牌、A 计点、黑杰克、五龙、平局重开、生命质押与结算。
- A–K 共 13 种点数技能、6 种遗物、3 种道具，以及爆牌后的回溯救场。
- 奖励选择、生命购买、永久加牌/删牌、轮回成长与三个结局分支。
- 永久牌库存档。当前路线、生命、遗物与道具不跨程序退出保存。
- 3D 占位牌桌叠加 2D 界面；最终三渲二材质、正式美术、声音和完整叙事待制作。

第一次游玩：开始轮回 → 选择升级 → 点击亮起的地图节点 → 质押发牌 → 要牌/停牌 → 领取奖励继续。卡牌和道具可悬停查看说明，牌桌提供规则入口。

设计选择见 `docs/玩法实现v0.2.md`，策划阅读整理见 `docs/飞书玩法阅读笔记.md`。

## 代码分工

| 文件 | 职责 |
| --- | --- |
| scripts/blackjack_match.gd | 牌局状态机、技能、道具与结算 |
| scripts/run_state.gd | 轮回、三幕推进与节点状态 |
| scripts/profile.gd | 永久牌库与存档 |
| scripts/game_catalog.gd | 技能、遗物、道具、Boss 定义 |
| scripts/card_data.gd、scripts/deck.gd | 卡牌实例、洗牌、抽弃牌 |
| scripts/map_generator.gd、scripts/route_view.gd | 地图生成与展示 |
| scripts/main.gd、scripts/ui_base.gd | 界面与流程连接 |
| scripts/table_stage.gd | 占位三维环境 |
| tests/smoke.gd | 规则边界、流程、存档及模拟检查 |

存档为 `user://memory_profile_v1.json`，编辑器“项目 → 打开用户数据文件夹”可定位。异常存档会提示并停止覆盖原文件。

## 验证

在 F:\gamejam 执行：

```powershell
& '.\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe' --headless --path '.\NightTable' --script res://tests/smoke.gd -- --smoke
& '.\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe' --path '.\NightTable' -- --capture
```

检查包括 100 个地图种子、120 次自动轮回、规则边界和界面流程。自动策略用于验证状态约束和终止性，不代表正式平衡评估。截图输出在 captures，包含人为设置的压力场景。两种模式不改玩家存档；存档往返测试使用独立临时文件。

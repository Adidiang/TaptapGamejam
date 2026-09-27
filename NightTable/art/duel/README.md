# 局内牌桌第一版

打开 `duel_table.tscn`，可调整木桌、烛台、书、酒杯、酒瓶和灯光；F6 预览背景。完整牌局通过 F5 进入战斗查看。

- `scripts/duel_table_art.gd`：牌桌专用手绘、光照参数，与探索房间的明暗区分。对手区域保持黑暗。
- `scripts/duel_table_view.gd`：将独立牌桌放入对战背景视口。
- `scripts/duel_card_art.gd`：原生绘制的纸牌边框、墨线符号、牌背和数字。当前功能牌用效果/加成/陷阱三类符号，逐张独立插画尚未制作。
- `scripts/duel_view.gd`：牌局显示布局，数字区和功能区可横向滚动，卡牌悬停查看效果。点击可用效果牌使用，弃掉按钮处理弃牌；回合开始可点击自有牌堆或底部按钮摸牌。

对手暗牌不传入真实牌面信息；结算时仅公开规则允许的加成牌。负荷、数值、操作合法性与胜负仍由 LoadDuel / DuelEncounter 管理。此版采用 3D 桌面背景与清晰的 2D 可交互牌面，尚未实现实体牌的透视摆放及发牌动画。

截图：`captures/encounter.png`、`encounter_full.png`、`encounter_settlement.png`。满牌截图是人为配置的布局压力画面，不是自然开局。

不要重跑 `art/tools/build_duel_table.gd` 覆盖手动调整；它只用于首次生成场景。

@tool
class_name Level1Whitebox
extends Node3D
## Level 1「卡牌王国」白盒（White Box）。
##
## 视角：横板正视图 —— 相机放在 +Z 朝 -Z 看，也就是设计图那种"正对着楼层看"的角度。
##   X = 房间排列方向（横向，关卡主推进轴）
##   Y = 楼层高度
##   Z = 进深（玩家在这个房间里前后走动的范围，只有 10 m）
##
## 结构来源：docs/设计图-楼层布局.jpg（飞书《关卡设计图初版》）
##
##   顶层                      [ Boss 房 ]（压在二楼大堂正上方）
##   二楼      [房][房][房]    二楼大堂    [房][房][房]      6 普通房
##   一楼  [房][商店][房][房] 一楼大堂 [房][房][商店][房]   6 普通房 + 2 商店
##
##   每层 3 战斗 + 2 事件 + 1 调查（图注：一个大关内每个类型房间数量固定）。
##   黄色格「商店」标注"可以通向上下方楼层"；一楼大堂"可以上到二楼楼梯"；
##   二楼大堂"收集到顶层钥匙后可以从此上顶层"。
##
## 竖直连接：
##   一楼大堂  --主楼梯-->              二楼大堂
##   两个商店  --店里靠后墙的楼梯-->    二楼正上方那间房
##   二楼大堂  --楼梯 + 单向门-->        顶层 Boss 房
##
## 白盒习惯（都是为了能一眼看清布局）：
##   · 前侧（Z+）只砌 1.1 m 矮墙 —— 横板相机能直接看进每个房间，人也不会掉下去
##   · 房间不盖天花板，俯视时能直接看穿
##   · 标签一律英文：Label3D 用默认字体，写中文会渲染成方块
##
## 编辑器预览：脚本带 @tool，双击 scenes/level1_whitebox.tscn 切到「3D」就能直接看，
## 改下面常量保存即刷新。
##
## 运行后操作（默认就是横板正视图，相机自动跟随玩家）：
##   Tab    横板正视图 / 第一人称巡走 切换
##   WASD   移动；Shift 加速；空格跳跃
##   鼠标   巡走模式转动视角（点画面捕获，Esc 释放）
##   滚轮   横板模式缩放视野
##   R      回到出生点

# ============================================================
# 尺寸常量（单位：米）
# ============================================================
## 层高。10 m：相机放大（fov 35°）后视野变窄，画面顶边在 z=-5 处看到的墙面高约 8 m，
## 10 m 层高的墙顶远在画面外 —— 看不到天花板，也看不到二楼楼板。
## 之前 fov 45° + 层高 14 m 是视野宽时要保证出画；放大后不用那么高，房间更紧凑。
const FLOOR_H := 10.0
const SLAB_T := 0.3                  # 楼板厚度
const WALL_T := 0.25                 # 墙厚
const WALL_H := FLOOR_H - SLAB_T     # 墙高（楼板正好架在墙顶）
## 前侧矮墙高度。0 = 不要前墙。横板相机是俯着往下看的，1.1 m 的墙会把
## 6~7 m 进深的地板整片挡住（俯角 9.5° 时 1.1 m 高的墙遮挡 1.1/sin9.5° ≈ 6.7 m，
## 而进深只有 10 m），而参考图里地面是一路看到墙脚的，所以这里留空。
## 想要「剖切面」的观感就调回 0.3~0.5，代价是地板少看一截。
const RAIL_H := 0.0

const SLOT_W := 16.0                 # 普通房沿 X 的宽度
const HALL_W := 24.0                 # 大堂沿 X 的宽度
const DEPTH := 10.0                  # 统一进深（Z），前后各 ±DEPTH/2
const HALF_D := DEPTH * 0.5

const DOOR_W := 4.0                  # 房间之间的门洞
const DOOR_H := 4.0
const HEAD_ROOM := 2.2               # 楼梯上方要保留的净空，用来反推楼板开口
const STAIR_STEPS := 14
const STAIR_W := 4.0                 # 楼梯宽度
const STAIR_RUN := 15.0              # 主楼梯 / 上顶层楼梯的水平跑距（层高 10 → 约 34°）
const STAIR_RUN_SHOP := 13.0         # 商店隐蔽楼梯的跑距（商店 16 m 宽，跑 13 m 不出商店）
const STAIR_FOOT_MAIN := -7.0        # 主楼梯起步 X（大堂内，跑 15 m 到 +8，不撞右墙）
const STAIR_FOOT_TOP := -8.0         # 上顶层楼梯起步 X（二楼大堂内，跑 15 m 到 +7）
const STAIR_FOOT_SHOP := -6.0        # 商店楼梯起步 X 相对商店中心（跑 13 m 到 +7，不出商店）
const STAIR_Z := -3.0                # 楼梯中心 Z：一律贴着后墙放

const BOSS_W := 46.0                 # 顶层 Boss 房沿 X 的宽度
const BOSS_H := 11.0                 # 顶层净高

const SPAWN := Vector3(-8.0, 0.4, 3.0)    # 出生点：一楼大堂前侧（避开主楼梯 X∈[-5,7] Z∈[-5,-1]）

# ------------------------------------------------------------
# 人物 —— 全场景的尺度基准。改这一个数，相机取景会跟着算。
# ------------------------------------------------------------
const PLAYER_H := 1.7                # 人物身高（米）
const PLAYER_RADIUS := 0.25          # 碰撞胶囊半径（CapsuleShape3D.height 是含两端的「总高」）
const EYE_OFFSET := 0.12             # 眼睛离头顶多远；巡走模式的相机高 = PLAYER_H - EYE_OFFSET
const PLAYER_TURN_SPEED := 12.0       # 横板下角色朝向移动方向的平滑转速

# ------------------------------------------------------------
# 横板相机
# 透视、站在 +Z 侧朝 -Z 看，再向下俯 CAM_PITCH_DEG。
# 关键：**相机 Z 固定，只跟玩家的 X/Y**。玩家前后走（Z 方向）时距相机距离变化，
# 会有真实的大小变化和前后景视差 —— 这就是「移动场景有透视变化」的来源。
# 正交相机没有这个效果（远近一样大），所以看着像贴纸。
# 取景按参考图反推（docs/参考图-横板构图2.jpg）：玩家在出生点 z=3 时距相机 13 m，
# 画面高 = 2×13×tan(fov/2) ≈ 12.1 m，人占画面 14%。
# ------------------------------------------------------------
const CAM_FOV := 35.0                # 透视视野角度（35° 长焦放大感，人占画面约 24%）
const CAM_Z := 14.0                  # 相机 Z 固定（距出生点玩家 11 m）。
									 # 拉近后画面底边扫在 z≈6 —— 房间地板内部，
									 # 延伸地板只需一点点，画面里看不到「房间外的地板」
const CAM_ASPECT := 16.0 / 9.0       # 16:9
const CAM_PITCH_DEG := 12.0          # 俯角（低头看地板进深）
const CAM_LIFT := 4.0                # 相机比玩家脚高多少（决定玩家在画面垂直位置）
const CAM_FOV_MIN := 30.0            # 滚轮拉近（长焦，透视弱）
const CAM_FOV_MAX := 80.0            # 滚轮推远（广角，透视强）
const CAM_LERP := 6.0                # 跟随玩家的平滑速度

## 地板向前延伸到的 Z。透视相机视野底边会扫到地面前缘之外的虚空，
## 地板延伸出画面底（横板游戏标配的前景地板）。相机拉近后（CAM_Z=14）
## 底边只扫到 z≈6.2，延伸到 6.5 就够 —— 画面里几乎看不到「房间外的地板」。
const FRONT_EXT := 7.0
const FORCE_WINDOW_169 := false      # 项目本体已是 16:9（project.godot），不用运行时强制

# ============================================================
# 槽位表 —— 改这里就能改布局。数组顺序是「从大堂往外」。
# 一楼两侧各 4 格（其中 1 格是商店），二楼两侧各 3 格。
# 图的注释写明：具体类型在大关内是随机分配的，只有数量固定（3 战斗 / 2 事件 / 1 调查），
# 所以下面这份是白盒走查用的固定样板，接玩法时换成随机即可。
# ============================================================
const F1_LEFT := [
	{"kind": "encounter"},
	{"kind": "event"},
	{"kind": "shop"},          # 一楼左侧的商店（可以通向上下方楼层）
	{"kind": "encounter"},
]
const F1_RIGHT := [
	{"kind": "investigate"},
	{"kind": "encounter"},
	{"kind": "shop"},          # 一楼右侧的商店
	{"kind": "event"},
]
const F2_LEFT := [
	{"kind": "encounter"},
	{"kind": "event"},
	{"kind": "encounter"},
]
const F2_RIGHT := [
	{"kind": "investigate"},
	{"kind": "encounter"},     # 2F-05：掉顶层钥匙的那间战斗房
	{"kind": "event"},
]

const LEVEL_LABEL := {
	"encounter": "ENCOUNTER",
	"event": "EVENT",
	"investigate": "INVESTIGATE",
	"shop": "SHOP",
	"hall": "GREAT HALL",
	"boss": "BOSS HALL",
}

# ============================================================
# 运行状态
# ============================================================
const MODE_SIDE := 0        # 横板正视图：相机在 +Z 朝 -Z 看，跟随玩家
const MODE_EXPLORE := 1     # 第一人称巡走：自己走一遍动线

var mode := MODE_SIDE
var side_camera: Camera3D
var player: CharacterBody3D
var head: Camera3D
var yaw := 0.0
var pitch := 0.0
var _materials: Dictionary = {}
var _debug_hud: Label
var _post_hud: Label


func _ready() -> void:
	_clear_generated()
	_build_lighting()
	_build_floor_one()
	_build_floor_two()
	_build_boss_floor()
	_build_stairs()
	if Engine.is_editor_hint():
		# 编辑器里也放一台横板相机：视口左上角 Perspective 菜单可以切过去预览。
		_build_side_camera()
		return
	_force_window_aspect()
	_build_player()
	_build_side_camera()
	_apply_mode()
	_build_lighting()
	_build_debug_hud()
	_report_scale()
	print("[whitebox] READY — 出生点 %s，模式横板。WASD 移动 / Shift 跑 / 空格跳 / R 重置 / Tab 切巡走 / B G 亮度 / V C 暗角 / O L SSAO / N 调参重置 / Esc 退出" % [SPAWN])


## 清掉上一轮代码生成的节点。只删 owner 为空的（= 代码建的），
## 手动在编辑器里加的节点 owner 是场景根，不会被误删。
func _clear_generated() -> void:
	for child in get_children():
		if child.owner == null:
			remove_child(child)
			child.free()


# ============================================================
# 楼层
# ============================================================

func _build_floor_one() -> void:
	_build_level(0.0, 1, F1_LEFT, F1_RIGHT, [])


func _build_floor_two() -> void:
	# 二楼的楼板同时就是二楼的地面；三个楼梯口在这里留洞。
	var holes: Array = []
	holes.append(_main_stair_hole())
	for sx in [-1.0, 1.0]:
		holes.append(_shop_stair_hole(sx))
	_build_level(FLOOR_H, 2, F2_LEFT, F2_RIGHT, holes)


## 铺一层：楼板 + 每格色块和标签 + 隔墙 + 后墙 + 前侧矮墙。
## holes 是楼板上沿后墙（Z 负侧）开的洞，每项 {x0, x1, z1}：
## 该 X 区段的楼板只从 z1 铺到 +HALF_D，Z ∈ [-HALF_D, z1] 那块是让出来的楼梯口。
func _build_level(base_y: float, level: int, left: Array, right: Array, holes: Array) -> void:
	var half_w := HALL_W * 0.5 + SLOT_W * float(maxi(left.size(), right.size()))
	_slab(base_y, half_w, holes)

	# 大堂
	_tile(base_y, 0.0, HALL_W, "hall", "%dF GREAT HALL" % level)

	# 左侧：数组是「从大堂往外」，房间编号却要从左往右，所以倒着取。
	for i in range(left.size()):
		var slot_index := left.size() - 1 - i
		var slot: Dictionary = left[slot_index]
		var x := _slot_x(-1.0, slot_index)
		_tile(base_y, x, SLOT_W, String(slot.kind),
			"%dF-%02d %s" % [level, i + 1, _label_of(String(slot.kind))])

	# 右侧：从大堂往外就是从左往右。
	for i in range(right.size()):
		var slot: Dictionary = right[i]
		var x := _slot_x(1.0, i)
		_tile(base_y, x, SLOT_W, String(slot.kind),
			"%dF-%02d %s" % [level, left.size() + i + 1, _label_of(String(slot.kind))])

	# 隔墙：每格的左右边界。最外那道是外墙（不开门），紧贴大堂那道开一个门连通道。
	for side_value in [-1.0, 1.0]:
		var side := float(side_value)
		var slots: Array = left if side < 0.0 else right
		for i in range(slots.size() + 1):
			var x: float = side * (half_w - SLOT_W * float(i))
			# i = 0 是最外那道外墙，不开门；其余（格与格之间、大堂与紧邻那格之间）都开门。
			_wall_at_x(x, base_y, WALL_H, i > 0)

	# 后墙（整条）+ 前侧矮墙 + 前缘隐形墙（拦住玩家，别走出延伸地板）
	_wall_at_z(-HALF_D, base_y, WALL_H, half_w)
	_wall_at_z(HALF_D, base_y, RAIL_H, half_w)
	_invisible_wall_at_z(HALF_D, base_y, half_w)


## 一层楼板。holes 只在 X 方向切分，因为楼梯口都贴着后墙开。
## 楼板从后墙一直铺到 FRONT_EXT（前侧延伸出房间，给透视相机当前景地板）。
func _slab(base_y: float, half_w: float, holes: Array) -> void:
	var cuts: Array = [-half_w, half_w]
	for hole in holes:
		cuts.append(float(hole.x0))
		cuts.append(float(hole.x1))
	cuts.sort()
	for i in range(cuts.size() - 1):
		var x0: float = cuts[i]
		var x1: float = cuts[i + 1]
		if x1 - x0 <= 0.02:
			continue
		var z_start := -HALF_D
		for hole in holes:
			if x0 >= float(hole.x0) - 0.05 and x1 <= float(hole.x1) + 0.05:
				z_start = float(hole.z1)
		var depth := FRONT_EXT - z_start
		if depth <= 0.02:
			continue
		# 楼板不投影：横板剖面视角下，太阳从上方打，二三层楼板会把整个一楼
		# 挡进影子里（开阴影后画面整体压暗、楼梯全黑的根因）。
		# 上层结构对光线「透明」，一楼才能像剖面图一样被照亮。
		_box(self, Vector3(x1 - x0, SLAB_T, depth),
			Vector3((x0 + x1) * 0.5, base_y - SLAB_T * 0.5, z_start + depth * 0.5),
			_color_of("floor"), true, false)


## 一格的类型色块 + 房名标签。
## 色块不投影：每层都有 tile，二三层的大薄片会把斜条影子投到一楼地板上。
## 色块沿 Z 一直铺到前缘延伸段（FRONT_EXT）：楼板本体是灰色的，若色块只铺到
## 房间前缘（z=+5），画面底部会出现「房间色 → 灰」的换色线，延伸段看着就像
## 房间外的地板。同色延续出画面，读起来才是「一块完整的地板」。
func _tile(base_y: float, cx: float, width: float, kind: String, text: String) -> void:
	var z0 := -HALF_D + 0.5
	var z1 := FRONT_EXT - 0.5
	_box(self, Vector3(width - 1.0, 0.06, z1 - z0),
		Vector3(cx, base_y + 0.03, (z0 + z1) * 0.5), _kind_color(kind), false, false)
	_label(self, text, Vector3(cx, base_y + 3.0, 0.0), 54, _kind_color(kind))


func _build_boss_floor() -> void:
	var base_y := FLOOR_H * 2.0
	var half_w := BOSS_W * 0.5
	var holes: Array = [_boss_stair_hole()]
	_slab(base_y, half_w, holes)
	_tile(base_y, 0.0, BOSS_W, "boss", "TOP FLOOR - BOSS HALL")

	for side_value in [-1.0, 1.0]:
		_wall_at_x(float(side_value) * half_w, base_y, BOSS_H, false)
	_wall_at_z(-HALF_D, base_y, BOSS_H, half_w)
	_wall_at_z(HALF_D, base_y, RAIL_H, half_w)
	_invisible_wall_at_z(HALF_D, base_y, half_w)

	# 王座占位
	_box(self, Vector3(5.0, 1.4, 3.2), Vector3(0.0, base_y + 0.7, -3.4), _color_of("prop"), true)
	_box(self, Vector3(3.6, 6.0, 0.7), Vector3(0.0, base_y + 3.0, -4.6), _color_of("prop"), true)
	# 单向门：只能从二楼大堂上来，回头出不去
	for side_value in [-1.0, 1.0]:
		_box(self, Vector3(0.8, 5.0, 0.8),
			Vector3(float(side_value) * 4.6, base_y + 2.5, -HALF_D + 0.6), _color_of("gate"), true)
	_label(self, "ONE-WAY GATE", Vector3(0.0, base_y + 5.6, -HALF_D + 1.2), 46, _color_of("gate"))


# ============================================================
# 楼梯
# ============================================================

func _build_stairs() -> void:
	# 一楼大堂 -> 二楼大堂
	_stair_x(STAIR_FOOT_MAIN, 0.0, STAIR_RUN, FLOOR_H, STAIR_W, STAIR_Z)
	_label(self, "STAIR TO 2F", Vector3(0.0, 3.6, STAIR_Z + 3.2), 46, _color_of("stair_label"))

	# 两个商店 -> 二楼正上方那间房。
	# 起点取 store_x - 5、朝 +X 跑 11 m，全程都落在商店内部（商店宽 16 m）；
	# 再往里跑就会捅穿到隔壁房间去。
	for sx_value in [-1.0, 1.0]:
		var sx := float(sx_value)
		var shop_x := _slot_x(sx, 2)          # 商店在「从大堂往外」的第 3 格
		_stair_x(shop_x + STAIR_FOOT_SHOP, 0.0, STAIR_RUN_SHOP,
			FLOOR_H, STAIR_W, STAIR_Z)
		_label(self, "SHOP STAIR",
			Vector3(shop_x, 3.6, STAIR_Z + 3.2), 42, _color_of("stair_label"))

	# 二楼大堂 -> 顶层 Boss 房
	_stair_x(STAIR_FOOT_TOP, FLOOR_H, STAIR_RUN, FLOOR_H, STAIR_W, STAIR_Z)
	_label(self, "STAIR TO TOP", Vector3(-1.0, FLOOR_H + 3.6, STAIR_Z + 3.2), 46, _color_of("stair_label"))


## 一部靠后墙、沿 +X 上升的直跑楼梯。
func _stair_x(foot_x: float, base_y: float, run: float, rise: float, width: float, center_z: float) -> void:
	_stair(Vector3(foot_x, base_y, center_z), Vector3(1.0, 0.0, 0.0), width, run, rise)


## 楼梯要穿过的楼板开口：从净空不足的那一点起，到楼梯顶端为止。
## 高度 y 处楼梯的 X = foot_x + run * (y / FLOOR_H)；
## 要人站得直，y 得 ≥ FLOOR_H - HEAD_ROOM。
func _stair_hole(foot_x: float, run: float, width: float, center_z: float) -> Dictionary:
	var gap_x := foot_x + (FLOOR_H - HEAD_ROOM) / FLOOR_H * run
	return {"x0": gap_x, "x1": foot_x + run, "z1": center_z + width * 0.5}


func _main_stair_hole() -> Dictionary:
	return _stair_hole(STAIR_FOOT_MAIN, STAIR_RUN, STAIR_W, STAIR_Z)


func _shop_stair_hole(sx: float) -> Dictionary:
	return _stair_hole(_slot_x(sx, 2) + STAIR_FOOT_SHOP, STAIR_RUN_SHOP, STAIR_W, STAIR_Z)


func _boss_stair_hole() -> Dictionary:
	return _stair_hole(STAIR_FOOT_TOP, STAIR_RUN, STAIR_W, STAIR_Z)


# ============================================================
# 构件
# ============================================================

## 某一格的中心 X。index 是「从大堂往外」的序号（0 = 紧挨大堂那一格）。
func _slot_x(side: float, index: int) -> float:
	return side * (HALL_W * 0.5 + SLOT_W * (float(index) + 0.5))


func _label_of(kind: String) -> String:
	return String(LEVEL_LABEL.get(kind, kind))


## 垂直于 X 的墙。door = true 时在 Z 中间留一个门洞。
func _wall_at_x(x: float, base_y: float, height: float, door: bool) -> void:
	# 墙体不投影：14 m 高的隔墙会把影子横穿地板和前景（白斜条），
	# 也给楼梯盖上一片黑。结构关系交给 SSAO 和墙面明暗，小物件才投影。
	if not door:
		_box(self, Vector3(WALL_T, height, DEPTH),
			Vector3(x, base_y + height * 0.5, 0.0), _color_of("wall"), true, false)
		return
	var half_gap := DOOR_W * 0.5
	for side_value in [-1.0, 1.0]:
		var side := float(side_value)
		var z0: float = side * half_gap
		var z1: float = side * HALF_D
		_box(self, Vector3(WALL_T, height, absf(z1 - z0)),
			Vector3(x, base_y + height * 0.5, (z0 + z1) * 0.5), _color_of("wall"), true, false)
	if DOOR_H < height - 0.02:
		_box(self, Vector3(WALL_T, height - DOOR_H, half_gap * 2.0),
			Vector3(x, base_y + DOOR_H + (height - DOOR_H) * 0.5, 0.0), _color_of("wall"), true, false)
	# 门框是小构件，保留投影 —— 门口的一小片影子是房间进深的线索。
	for edge_value in [-half_gap, half_gap]:
		_box(self, Vector3(WALL_T + 0.12, DOOR_H, 0.22),
			Vector3(x, base_y + DOOR_H * 0.5, float(edge_value)), _color_of("frame"))


## 垂直于 Z 的一整条墙（后墙 / 前侧矮墙）。height <= 0 表示这面墙不要（见 RAIL_H）。
func _wall_at_z(z: float, base_y: float, height: float, half_w: float) -> void:
	if height <= 0.01:
		return
	# 后墙不投影：高墙影子会盖住贴墙的楼梯和大半地板（峡谷效应）。
	_box(self, Vector3(half_w * 2.0, height, WALL_T),
		Vector3(0.0, base_y + height * 0.5, z), _color_of("wall"), true, false)


## 房间前缘的隐形碰撞墙：只有碰撞没有视觉。
## 地板向前延伸了（FRONT_EXT），不拦的话玩家会走出房间、走到画面外。
func _invisible_wall_at_z(z: float, base_y: float, half_w: float) -> void:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(half_w * 2.0, FLOOR_H * 2.0, 0.5)
	collision.shape = shape
	body.add_child(collision)
	body.position = Vector3(0.0, base_y + FLOOR_H, z)
	add_child(body)


## 生成一段直跑楼梯。视觉是悬空踏板，碰撞用一个旋转的斜面，保证能顺滑走上去。
## foot 是脚下的地面点；dir 是水平前进方向（只支持 ±X / ±Z）。
func _stair(foot: Vector3, dir: Vector3, width: float, run: float, rise: float) -> void:
	if run <= 0.0 or rise <= 0.0:
		return
	var step_run := run / float(STAIR_STEPS)
	var step_rise := rise / float(STAIR_STEPS)
	var is_x := absf(dir.x) > 0.5
	for i in range(STAIR_STEPS):
		var distance := step_run * (float(i) + 0.5)
		var height := step_rise * float(i + 1)
		var center := foot + dir * distance + Vector3.UP * (height - 0.15)
		var size := Vector3(step_run + 0.08, 0.3, width) if is_x else Vector3(width, 0.3, step_run + 0.08)
		# 台阶不投影：楼梯是 14 m 的斜长结构，贴墙堆叠 —— 上层楼梯/台阶
		# 会把下层整条盖进影子里（主楼梯全黑的根因）。立体感交给
		# 台阶立面背光 + SSAO，剖面楼里这是唯一干净的做法。
		_box(self, size, center, _color_of("stair"), false, false)

	var length := sqrt(run * run + rise * rise)
	var slope_dir := (dir * run + Vector3.UP * rise).normalized()
	var wide := Vector3.UP.cross(slope_dir)
	if wide.length() < 0.01:
		return
	wide = wide.normalized()
	var normal := slope_dir.cross(wide).normalized()
	if normal.y < 0.0:
		normal = -normal
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(length, 0.4, width)
	collision.shape = shape
	body.add_child(collision)
	body.transform = Transform3D(Basis(slope_dir, normal, wide),
		foot + dir * (run * 0.5) + Vector3.UP * (rise * 0.5))
	add_child(body)


# ============================================================
# 工具
# ============================================================

func _box(parent: Node3D, size: Vector3, at: Vector3, color: Color, solid := false,
		casts_shadow := true) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = _material(color)
	instance.position = at
	if not casts_shadow:
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	if solid:
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		body.position = at
		parent.add_child(body)


func _material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.94
		_materials[key] = material
	return _materials[key]


func _label(parent: Node3D, text: String, at: Vector3, font_size: int, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.pixel_size = 0.007
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.outline_size = 14
	label.modulate = color
	label.position = at
	parent.add_child(label)


func _color_of(token: String) -> Color:
	match token:
		"floor": return Color("575757")
		"wall": return Color("8f8f8f")
		"rail": return Color("a8a8a8")
		"stair": return Color("6f6f6f")
		"prop": return Color("7a7166")
		"frame": return Color("d8cb9a")
		"stair_label": return Color("cfe0ea")
		"gate": return Color("e0b45c")
		"player": return Color("f2ece0")
		"player_face": return Color("3a3f46")
	return Color("888888")


func _kind_color(kind: String) -> Color:
	match kind:
		"encounter": return Color("a2544a")
		"event": return Color("4a6ba2")
		"investigate": return Color("4a9670")
		"shop": return Color("bda05a")
		"hall": return Color("c2ad84")
		"boss": return Color("8f5aa2")
	return Color("6f6f6f")


## 把灯光统一抽成独立场景 scenes/lighting_env.tscn —— 想「在 Inspector 里
## 调灯光」就改那个 tscn；art_preview 也 instance 同一份，两边永远一致。
## 旧的「代码现生成 WorldEnvironment + Sun + Fill」对照值见 git 历史。
const LIGHTING_SCENE := preload("res://scenes/lighting_env.tscn")


func _build_lighting() -> void:
	for c in get_children():
		if c.name == "LightingEnv":
			c.queue_free()
	var env := LIGHTING_SCENE.instantiate()
	env.name = "LightingEnv"
	add_child(env)
	if Engine.is_editor_hint():
		env.set_owner(self)


## 白盒专用的 16:9 窗口。只调运行时窗口，**不动 project.godot** ——
## 游戏本体的 1440×900 是团队定的，不该被白盒带跑。
func _force_window_aspect() -> void:
	if not FORCE_WINDOW_169 or DisplayServer.get_name() == "headless":
		return
	var usable := DisplayServer.screen_get_usable_rect(
		DisplayServer.window_get_current_screen())
	var height := mini(900, int(float(usable.size.y) * 0.86))
	var width := int(round(float(height) * CAM_ASPECT))
	DisplayServer.window_set_size(Vector2i(width, height))
	DisplayServer.window_set_position(
		usable.position + (usable.size - Vector2i(width, height)) / 2)


## 画面左上角的实时调试 HUD：显示玩家坐标、速度、是否着地。
## 动不了的时候看这里 —— pos 不变 = 被卡住；vel 有值但 pos 不变 = 撞墙弹回；
## HUD 完全不出现 = _ready 没跑完（player 为 null，控制台会有报错）。
func _build_debug_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	_debug_hud = Label.new()
	_debug_hud.position = Vector2(24, 24)
	_debug_hud.add_theme_font_size_override("font_size", 28)
	_debug_hud.add_theme_color_override("font_color", Color("cfe0ea"))
	_debug_hud.add_theme_color_override("font_outline_color", Color("000000"))
	_debug_hud.add_theme_constant_override("outline_size", 8)
	canvas.add_child(_debug_hud)
	# 后处理调节 HUD：左下角，显示当前后处理参数
	_post_hud = Label.new()
	_post_hud.position = Vector2(24, 200)
	_post_hud.add_theme_font_size_override("font_size", 24)
	_post_hud.add_theme_color_override("font_color", Color("ffd9a0"))
	_post_hud.add_theme_color_override("font_outline_color", Color("000000"))
	_post_hud.add_theme_constant_override("outline_size", 6)
	canvas.add_child(_post_hud)
	_update_post_hud()


## 实时调后处理：brightness/vignette/ssao 三组参数，reset 复位。
## 改的是 lighting_env.tscn 在场景里 instance 出来的 Environment 资源。
## 注意：直接改 Environment 资源会改 .tscn，但 instance scene 时的副本是共享的，所以游戏里改一次，重载 tscn 就回到原值。
func _adjust_post(what: String, delta: float) -> void:
	match what:
		"brightness":
			var env_b := _get_env()
			if env_b == null:
				return
			env_b.adjustment_enabled = true
			env_b.adjustment_brightness = clampf(env_b.adjustment_brightness + delta, 0.2, 3.0)
		"vignette":
			var mat := _get_vignette_mat()
			if mat:
				mat.set_shader_parameter("intensity",
					clampf(float(mat.get_shader_parameter("intensity")) + delta, 0.0, 2.0))
		"ssao":
			var env_s := _get_env()
			if env_s == null:
				return
			env_s.ssao_enabled = true
			env_s.ssao_intensity = clampf(env_s.ssao_intensity + delta, 0.0, 8.0)
		"reset":
			var env_r := _get_env()
			if env_r:
				env_r.adjustment_brightness = 1.0
				env_r.adjustment_contrast = 1.0
				env_r.adjustment_saturation = 1.0
				env_r.ssao_intensity = 2.5
			var mat_r := _get_vignette_mat()
			if mat_r:
				mat_r.set_shader_parameter("intensity", 0.4)
	if _post_hud:
		_update_post_hud()


func _get_vignette_mat() -> ShaderMaterial:
	for c in get_children():
		if c is Node and c.name == "LightingEnv":
			var layer: Node = c.get_node_or_null("VignetteLayer")
			if layer is CanvasLayer:
				var rect: Node = layer.get_node_or_null("Vignette")
				if rect is ColorRect and rect.material is ShaderMaterial:
					return rect.material as ShaderMaterial
	return null


func _get_env() -> Environment:
	for c in get_children():
		if c is Node and c.name == "LightingEnv":
			var env_node: Node = c.get_node_or_null("Env")
			if env_node is WorldEnvironment:
				return (env_node as WorldEnvironment).environment
	return null


func _update_post_hud() -> void:
	var env := _get_env()
	if env == null or _post_hud == null:
		return
	var vig := 0.0
	var mat := _get_vignette_mat()
	if mat:
		vig = float(mat.get_shader_parameter("intensity"))
	_post_hud.text = "B/G  亮度 %.2f\nV/C  暗角 %.2f\nO/L  SSAO %.2f\nN    重置\nEsc  退出" \
		% [env.adjustment_brightness, vig, env.ssao_intensity]


## 把「比例尺」打到输出里，方便跟策划对数字用。
func _report_scale() -> void:
	var dist_spawn := CAM_Z - SPAWN.z
	var frame_h := 2.0 * dist_spawn * tan(deg_to_rad(CAM_FOV * 0.5))
	print("[whitebox] 人物 %.2f m；透视 fov %.0f°，出生点距相机 %.1f m，画面高 %.1f m，人占画面 %.0f%%"
		% [PLAYER_H, CAM_FOV, dist_spawn, frame_h, PLAYER_H / frame_h * 100.0])
	print("[whitebox] 层高 %.1f m = 人身高的 %.1f 倍；俯角 %.1f°；相机高 %.2f m"
		% [FLOOR_H, FLOOR_H / PLAYER_H, CAM_PITCH_DEG, _cam_lift()])


# ============================================================
# 视角与移动
# ============================================================

## 横板相机：透视，站在 +Z 侧朝 -Z 看（画面里 +X 向右、+Y 向上），
## 再向下俯 CAM_PITCH_DEG。Z 固定，只跟玩家 X/Y —— 玩家前后走时距相机距离变化，
## 产生真实透视（远近大小不同、前后景视差）。
func _build_side_camera() -> void:
	side_camera = Camera3D.new()
	side_camera.name = "SIDE_CAM"
	side_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	side_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	side_camera.fov = CAM_FOV
	side_camera.near = 0.1
	side_camera.far = 200.0
	# 负角度 = 低头（Godot 里绕 +X 正向转是抬头）。
	side_camera.rotation = Vector3(-deg_to_rad(CAM_PITCH_DEG), 0.0, 0.0)
	side_camera.position = Vector3(SPAWN.x, SPAWN.y + _cam_lift(), CAM_Z)
	add_child(side_camera)


## 相机比玩家脚底高多少。透视模式下这是个固定值（CAM_LIFT），
## 决定玩家落在画面垂直位置的哪里 —— 值越大相机越高，玩家越靠画面下方。
func _cam_lift() -> float:
	return CAM_LIFT


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "PLAYER"
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = PLAYER_RADIUS
	capsule.height = PLAYER_H
	collision.shape = capsule
	collision.position = Vector3(0.0, PLAYER_H * 0.5, 0.0)
	player.add_child(collision)

	# 可见的身体 —— 白盒里人必须看得见，否则没法判断建筑尺度对不对。
	var body := MeshInstance3D.new()
	body.name = "BODY"
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = PLAYER_RADIUS
	body_mesh.height = PLAYER_H
	body.mesh = body_mesh
	body.material_override = _material(_color_of("player"))
	body.position = Vector3(0.0, PLAYER_H * 0.5, 0.0)
	player.add_child(body)

	# 朝向标记：贴在身前的小方块，一眼看出角色面朝 +X（画面右方）。
	var nose := MeshInstance3D.new()
	nose.name = "NOSE"
	var nose_mesh := BoxMesh.new()
	nose_mesh.size = Vector3(0.16, 0.3, 0.26)
	nose.mesh = nose_mesh
	nose.material_override = _material(_color_of("player_face"))
	nose.position = Vector3(PLAYER_RADIUS + 0.05, PLAYER_H * 0.62, 0.0)
	player.add_child(nose)

	head = Camera3D.new()
	head.position = Vector3(0.0, PLAYER_H - EYE_OFFSET, 0.0)
	head.fov = 78.0
	head.current = false
	player.add_child(head)
	player.position = SPAWN
	add_child(player)


func _apply_mode() -> void:
	if mode == MODE_SIDE:
		side_camera.current = true
		# 横板下不动 rotation.y：角色会用 _physics_process 里平滑转向，朝向走的方向。
		player.velocity = Vector3.ZERO
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		head.current = true
		player.position = SPAWN
		player.velocity = Vector3.ZERO
		yaw = 0.0
		pitch = 0.0
		_apply_look()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _apply_look() -> void:
	player.rotation.y = yaw
	head.rotation.x = pitch


func _toggle_mode() -> void:
	mode = MODE_EXPLORE if mode == MODE_SIDE else MODE_SIDE
	_apply_mode()


func _move_input() -> Vector2:
	var value := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		value.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		value.y += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		value.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		value.x += 1.0
	return value.normalized()


## 横板相机跟随玩家：X/Y 平滑追，Z 固定在 CAM_Z（透视下 Z 固定才会产生远近透视变化）。
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if mode == MODE_SIDE:
		var target := Vector3(player.position.x, player.position.y + _cam_lift(), CAM_Z)
		side_camera.position = side_camera.position.lerp(target, clampf(CAM_LERP * delta, 0.0, 1.0))
	if _debug_hud:
		_debug_hud.text = "pos (%.1f, %.1f, %.1f)\nvel (%.1f, %.1f, %.1f)\nfloor %s" % [
			player.position.x, player.position.y, player.position.z,
			player.velocity.x, player.velocity.y, player.velocity.z,
			player.is_on_floor()]


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not player.is_on_floor():
		player.velocity.y -= 26.0 * delta
	var move := _move_input()
	var speed := 13.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 5.2
	# 横板下按世界轴走（A/D 沿 X、W/S 沿 Z）；巡走下按视角朝向走。
	var basis := Basis.IDENTITY if mode == MODE_SIDE else player.transform.basis
	var direction := (basis * Vector3(move.x, 0.0, move.y)).normalized()
	player.velocity.x = direction.x * speed
	player.velocity.z = direction.z * speed
	if Input.is_physical_key_pressed(KEY_SPACE) and player.is_on_floor():
		player.velocity.y = 6.5
	player.move_and_slide()
	# 横板模式下，让角色朝向移动方向（鼻子跟着走的方向）。
	if mode == MODE_SIDE and direction.length_squared() > 0.001:
		var target_yaw := atan2(-direction.z, direction.x)
		# 把角度差归一到 [-π, π] 再插值，避免绕远路 + 跨过 ±π 时跳变。
		var diff := fmod(target_yaw - player.rotation.y + PI, TAU) - PI
		player.rotation.y += diff * clampf(PLAYER_TURN_SPEED * delta, 0.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_TAB:
				_toggle_mode()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				# 任何模式都允许 Esc 退出游戏窗口捕获；巡走模式额外释放鼠标。
				if mode == MODE_EXPLORE:
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				get_tree().quit()
			KEY_R:
				player.position = SPAWN
				player.velocity = Vector3.ZERO
				yaw = 0.0
				pitch = 0.0
				_apply_look()
			# —— 实时灯光 / 后处理调节（运行时调整，无需切场景）——
			# 用对称字母键，避开笔记本 F1-F3 默认功能（亮度/音量/键盘背光）。
			# B = 亮度+   G = 亮度-   V = 暗角+   C = 暗角-   O = SSAO+   L = SSAO-   N = 重置
			KEY_B:
				_adjust_post("brightness", 0.1)
				get_viewport().set_input_as_handled()
			KEY_G:
				_adjust_post("brightness", -0.1)
				get_viewport().set_input_as_handled()
			KEY_V:
				_adjust_post("vignette", 0.05)
				get_viewport().set_input_as_handled()
			KEY_C:
				_adjust_post("vignette", -0.05)
				get_viewport().set_input_as_handled()
			KEY_O:
				_adjust_post("ssao", 0.2)
				get_viewport().set_input_as_handled()
			KEY_L:
				_adjust_post("ssao", -0.2)
				get_viewport().set_input_as_handled()
			KEY_N:
				_adjust_post("reset", 0.0)
				get_viewport().set_input_as_handled()
	if mode == MODE_SIDE and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			side_camera.fov = maxf(CAM_FOV_MIN, side_camera.fov - 2.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			side_camera.fov = minf(CAM_FOV_MAX, side_camera.fov + 2.0)
	if mode == MODE_EXPLORE:
		if event is InputEventMouseButton and event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			yaw -= event.relative.x * 0.0024
			pitch = clampf(pitch - event.relative.y * 0.0024, -1.35, 1.35)
			_apply_look()

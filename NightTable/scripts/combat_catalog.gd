class_name CombatCatalog
extends RefCounted
## Prototype deck factory; replace with resource-backed deck lists when design settles.
const SLOT_LIMIT := 3
const LOAD_LIMIT := 21
const FUNCTIONS := [
	["boost","鼓舞",2,"boost",3,"self","自己的最大数字牌 +3。"],
	["lighten","卸重",2,"lighten",2,"self","自己的负荷最高数字牌减负荷2，最低为1。"],
	["cut","干扰",3,"cut",3,"opponent","对方最大数字牌 -3，最低为0；不能影响已停牌者。"],
	["release","舍弃",1,"release",0,"self","移除自己最小的数字牌，同时释放其负荷。"],
	["scout","预见",1,"scout",2,"self","查看自己牌库顶的两张牌。"],
	["rally","齐心",3,"rally",1,"self","自己每张数字牌+1。"],
	["weaken","削弱",1,"weaken",2,"opponent","对方最小数字牌-2，最低0。"],
	["margin","余裕",2,"percent",10,"self","保留至结算：点数+10%。","bonus"],
	["confidence","底气",2,"flat",3,"self","保留至结算：固定加3点。","bonus"],
	["formation","成阵",3,"formation",5,"self","结算时至少5张数字牌，固定加5点。","bonus"],
	["snare","绊索",2,"snare",4,"opponent","对方摸入数字≥7且未超限：该牌-4，最低0。","trap","number_drawn"],
	["counter","反制",3,"cut",3,"opponent","对方成功使用效果牌后，其最大数字牌-3。","trap","effect_played"],
	["tripwire","戒线",2,"cut",5,"opponent","对方结束操作回合且数字总和≥20：最大数字牌-5。","trap","turn_ended"],
]
const STARTER_FUNCTIONS := [0,1,2,3,4,5,6,7,8,9,10,11,12,0,1,10]

static func number_card(value: int, cost: int) -> CombatCard:
	var card := CombatCard.new()
	card.key = "number_%d_%d" % [value,cost]
	card.title = "数字 %d" % value
	card.number = value
	card.load_cost = cost
	return card

static func function_card(index: int) -> CombatCard:
	var data: Array = FUNCTIONS[index]
	var card := CombatCard.new()
	card.key = data[0]
	card.title = data[1]
	card.kind = "function"
	card.load_cost = data[2]
	card.effect = data[3]
	card.amount = data[4]
	card.target = data[5]
	card.description = data[6]
	if data.size()>7: card.function_type = data[7]
	if data.size()>8: card.trigger = data[8]
	return card

static func from_profile(profile: MemoryProfile) -> Array[CombatCard]:
	var result: Array[CombatCard] = []
	# Preserve permanent additions/deletions without changing the legacy save format.
	# Fixed 16-face mapping covers all three function types without save migration.
	for entry in profile.cards:
		var rank := int(entry.rank)
		if rank <= 9:
			result.append(number_card(rank,clampi(ceili(rank/2.0),1,5)))
		else:
			result.append(function_card(STARTER_FUNCTIONS[(rank-10)*4+int(entry.suit)]))
	return result

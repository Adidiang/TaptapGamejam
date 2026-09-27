class_name RelicCatalog
extends RefCounted
const DATA := {
	"R01":["铜制配重环","负荷上限+2。"],
	"R02":["暗袋","功能槽+1。"],
	"R03":["磨损砝码","每小局首张数字牌负荷-1（最低1），入场超限检查前生效。"],
	"R04":["静默怀表","主动停牌时负荷≤12，本小局结算固定+4。"],
	"R05":["织线梭","每小局首次成功触发自己的陷阱，结算固定+3；停牌后仍有效。"],
	"R06":["裂纹王冠","结算+15%；代价：负荷上限-2。"],
	"R07":["独行烛台","至少4张数字牌时结算固定+6；代价：功能槽-1。"],
	"R08":["地窖铜钥","开启地窖铜锁门，不消耗。"],
	"R09":["停摆齿轮","启动钟机，开启隐藏梯子；每小局发牌后私下查看自有牌库顶1张。"],
	"R10":["无名者印记","负荷上限-1；启动钟机并击败Boss后可选择归还姓名结局。"]
}
static func text(id: String) -> String:
	return DATA[id][0]+"\n"+DATA[id][1]

static func limit_delta(ids: Array) -> int:
	return (2 if "R01" in ids else 0)-(2 if "R06" in ids else 0)-(1 if "R10" in ids else 0)

static func slot_delta(ids: Array) -> int:
	return (1 if "R02" in ids else 0)-(1 if "R07" in ids else 0)

static func on_number(side: Dictionary, card: Dictionary) -> void:
	if "R03" in side.relics and not side.weight_used:
		side.weight_used = true
		card.load = maxi(1,card.load-1)

static func on_stop(side: Dictionary, current_load: int) -> void:
	if "R04" in side.relics and current_load<=12: side.watch_bonus = 4

static func on_trap(side: Dictionary) -> void:
	if "R05" in side.relics: side.trap_bonus = 3

static func settlement(side: Dictionary) -> Dictionary:
	var names: Array[String] = []
	var flat: int = side.watch_bonus+side.trap_bonus
	if side.watch_bonus>0: names.append("静默怀表 +4")
	if side.trap_bonus>0: names.append("织线梭 +3")
	if "R07" in side.relics and side.numbers.size()>=4:
		flat += 6
		names.append("独行烛台 +6")
	var percent := 15 if "R06" in side.relics else 0
	if percent>0: names.append("裂纹王冠 +15%")
	return {"flat":flat,"percent":percent,"names":names}

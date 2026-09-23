class_name NightRun
extends RefCounted
var profile: MemoryProfile
var run_seed := 0
var act := 0
var hp := 100
var layers: Array = []
var visited: Array[int] = []
var total_visited := 0
var current_node: Dictionary = {}
var deck := MemoryDeck.new()
var rng := RandomNumberGenerator.new()
var relics: Array[String] = []
var items: Array[String] = []
var active := false
var pending := false
var encounter_count := 0
var legacy_text := ""
var ending := ""

func begin(new_seed: int,memory: MemoryProfile = null) -> void:
	profile = memory if memory != null else MemoryProfile.new()
	run_seed = new_seed
	rng.seed = new_seed
	act = 0
	hp = 100
	relics.clear()
	items.assign(["undo"])
	active = true
	total_visited = 0
	ending = ""
	legacy_text = ""
	_new_act()

func _new_act() -> void:
	layers = RouteGenerator.generate(run_seed+act*7919)
	for layer in layers:
		for node in layer:
			if node.row in [0,3,5]: node.kind = "encounter"
			elif node.row == 2: node.kind = "event" if node.column%2 == 0 else "rest"
			elif node.row == 4: node.kind = "shop"
	visited.clear()
	current_node = {}
	pending = false
	encounter_count = 0
	deck = profile.make_deck(run_seed+act*997)

func available_ids() -> Array:
	if not active or pending: return []
	if current_node.is_empty(): return [layers[0][0].id]
	return current_node.next

func find_node(node_id: int) -> Dictionary:
	for layer in layers:
		for node in layer:
			if node.id == node_id: return node
	return {}

func enter(node_id: int) -> bool:
	if node_id not in available_ids(): return false
	current_node = find_node(node_id)
	visited.append(node_id)
	total_visited += 1
	pending = true
	if current_node.kind == "encounter": encounter_count += 1
	return true

func nominal_stake() -> int:
	if current_node.get("kind") == "boss": return hp
	return [50,30,15,8][mini(maxi(encounter_count-1,0),3)]

func heal(amount: int) -> void:
	hp = clampi(hp+amount,0,100)

func finish_node() -> void:
	if not active or not pending: return
	pending = false
	if hp <= 0: finish_run(false)
	elif current_node.kind == "boss":
		if act == 2: finish_run(hp > 1)
		else:
			act += 1
			_new_act()

func finish_run(victory: bool) -> void:
	if not active: return
	active = false
	pending = false
	ending = "release" if victory and profile.removed_old >= 8 else ("dawn" if victory else "again")
	profile.loops += 1
	var options := profile.upgrade_choices(rng,1)
	if not options.is_empty():
		profile.upgrade(options[0])
		legacy_text = "带往下次轮回：%s · %s 已升级" % [GameCatalog.rank_name(options[0]),GameCatalog.SKILLS[options[0]][0]]
	else: legacy_text = "所有点数均已升级，牌库与删除记录继续保留。"
	profile.save_profile()

func add_relic(id: String) -> bool:
	if not GameCatalog.RELICS.has(id) or id in relics or relics.size() >= 6: return false
	relics.append(id)
	return true

func remove_memory(id: String) -> bool:
	if not profile.remove_card(id): return false
	if "release" in relics: heal(3)
	return true
